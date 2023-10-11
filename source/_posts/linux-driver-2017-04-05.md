---
title: linux字符驱动学习
date: 2017-04-05 21:19:02
categories: linux驱动
tags: [linux驱动]
---
所谓适合自己的才是最好的。学习知识也是如此，同一个知识点，有些人这样讲，但是另外的人按照别的方式讲解。当然不同的讲解方式对于该知识点的正确性自然是不至于错，然而每个人的理解能力以及认知有所差异，因此对知识的最终的吸收程度往往因人而异。而我就是那个理解以及认知能力奇差的那个/(ㄒoㄒ)/~~，废话暂且不说，进入正题。
# 基本知识
## linux设备分类
主要分为这样几类：
**1.字符设备(包括一个杂项设备)**
**2.块设备**
**3.网络设备**
<!-- more -->
## linux内核模块结构
```C
#include<linux/module.h>

MODELE_LICENSE("Dual BSD/GPL");
MODELE_AUTHOR("XXXX");
MODELE_DESCRIPTION("XXXX");

static void __init function_init(void)
{
}

static void __exit function_exit(void)
{
}
module_init(function_init);
module_exit(function_exit);
```
linux中所有驱动的编写都是基于此模板，另外linux模块也支持参数传递，支持传递的参数类型有：`int,long,short,uint`等。主要的函数有下面两种：
```C
module_param(name,type,perm); //支持单个参数
module_param_array(name,type,*num,perm);//支持输入数组
```
具体使用方法：
```C
int arg0;
int array[10];
int arrayNum;

module_param(arg0,int,S_IRUSR);
module_param_array(array,int,&arrayNum,S_IRUSR);

insmod XXX.ko arg0=10 array=1,2,3,4   //等号左右不要有空格
```
# 字符设备驱动
任何复杂事物的有条不紊运行都离不开一个个事先规划好的约束条件，linux系统也是如此。linux中的驱动有很多，那么上层应用如何在茫茫“驱动”的海中找到自己想要的那个TA呢？
首先你得要知道TA的一个信息：姓名、ID什么的都可以啦~所以作为驱动个体来说都必须有自己的ID，这个ID也就是设备号了，但是-------linux中的设备号却只有256个。这样的话千千万万的屌丝驱动连一个身份证都没有，还想迎娶白富美走上人生巅峰，你痴人说梦呢。话又说回来，瘸子里面挑将军，茫茫驱动海中驱动也能分个三六九等，这样问题就解决了嘛。每个驱动都还是有一个号码，但是由两部分组成-->主ID和次ID。主ID就对应着`主设备号`，代表我们都是一类嘛。次ID对应`次设备号`，代表着一类中的某一个。这样通过主次设备号的结合就能够确定到每一个具体的驱动了，于是就有无限可能了~（虽然你丑，但是说不准有人眼瞎呢T^T）
另外通过命令`cat /proc/devices`就可以查看当前系统挂载的各种设备:
![字符设备](/img/chardev.png)
## 标准字符驱动
字符设备是linux设备中的一大类，大多数的驱动开发也是围绕着字符设备来进行的，所以掌握字符驱动的开发也是极为重要哒~
对于字符设备驱动的开发主要有这几个步骤：
**1.给字符设备分配ID，也就是设备号了，这里会涉及动态和静态分配。**
**2.注册字符类设备，如果是多个同类设备的话还需要创建设备类。**
描述字符类设备的结构体以及主要函数：`include/linux/cdev.h`和`char_dev.c`
```C
struct cdev 
{
	struct kobject kobj;
	struct module *owner;
	const struct file_operations *ops;
	struct list_head list;
	dev_t dev;
	unsigned int count;
};

void cdev_init(struct cdev *, const struct file_operations *);

struct cdev *cdev_alloc(void);

int cdev_add(struct cdev *, dev_t, unsigned);

void cdev_del(struct cdev *);
```
动态和静态申请设备号以及释放设备号:
```C
int register_chrdev_region(dev_t from, unsigned count, const char *name);
int alloc_chrdev_region(dev_t *dev, unsigned baseminor, unsigned count,const char *name);
void unregister_chrdev_region(dev_t from, unsigned count);
```
创建和摧毁设备类：`Include/linux/device.h`
```C
struct device *device_create(struct class *cls, struct device *parent,
				    dev_t devt, void *drvdata,
				    const char *fmt, ...);
void device_destroy(struct class *cls, dev_t devt);                    
struct class* class_create(struct module *owner,const char *name);
void class_destroy(struct class *cls);
```
下面一个实例展示多个同类字符设备驱动的编写：
```C
#include<linux/init.h>
#include<linux/module.h>
#include<linux/moduleparam.h>
#include<linux/stat.h>

#include <linux/device.h>
#include <linux/fs.h>
#include <linux/kdev_t.h>
#include <linux/cdev.h>

#include <linux/slab.h>

#define DEVICE_NAME "myCharDevice"
#define DEVICE_NUM  5
#define MAJOR_  0
#define MINOR_  0

static int char_major = MAJOR_;
static int char_minor = MINOR_;
static int charId;
module_param(char_major,int,S_IRUSR);
module_param(char_minor,int,S_IRUSR);

MODULE_LICENSE("Dual BSD/GPL");
MODULE_AUTHOR("Sycamore");
MODULE_DESCRIPTION("This is a char driver test!\n");

struct charDevice 
{
    char name[10];
    int data;
    struct cdev dev;
};
struct charDevice *myCharDevice ;
struct class *myClass;
struct file_operations fileOps = 
{
    //一些操作函数并没有实现
  .owner = THIS_MODULE,  
};

static int __init char_init(void)
{
    int ret,i;
    //申请设备号
    if(char_major)//手动分配设备号
    {
        charId = MKDEV(char_major,char_minor);
        ret = register_chrdev_region(charId,DEVICE_NUM,DEVICE_NAME);
        
        if(ret < 0) 
        {
            printk(KERN_EMERG "register_chrdev_region failed!!\n");
            goto fail;
        }
    }
    else//自动分配设备号
    {
        printk(KERN_EMERG "alloc_chrdev_region works!\n");
        ret = alloc_chrdev_region(&charId,0,DEVICE_NUM,DEVICE_NAME);
        if(ret < 0) 
        {
            printk(KERN_EMERG "alloc_chrdev_region failed!!\n");
            goto fail;
        }
        char_major = MAJOR(charId);
        char_minor = MINOR(charId);
    }
    printk(KERN_EMERG "Success!! Major is: %d ,MINOR is %d.\n",char_major,char_minor);
    
    //申请字符设备类
    myClass = class_create(THIS_MODULE,DEVICE_NAME);
    myCharDevice = kmalloc(DEVICE_NUM * sizeof(struct charDevice) , GFP_KERNEL);
    if(!myCharDevice)
    {
        printk(KERN_EMERG "Kmailloc failed!!\n");
        ret = -ENOMEM;
        goto fail;
    }
    memset(myCharDevice,0,(DEVICE_NUM * sizeof(struct charDevice)));
    //依次注册每个字符
    for(i = 0; i < DEVICE_NUM; i++)
    {
        cdev_init(&(myCharDevice[i].dev),&fileOps);
        myCharDevice[i].dev.owner = THIS_MODULE;
        ret = cdev_add(&(myCharDevice[i].dev),MKDEV(char_major,(char_minor + i)),1);
        if(ret) 
        {
            printk(KERN_EMERG "Cdev_add failed!!\n");
            break;
            goto fail;
        }
        device_create(myClass,NULL,MKDEV(char_major,char_minor + i),NULL,DEVICE_NAME"%d",i);
    }
    
    return 0;
fail:

    unregister_chrdev_region(charId,DEVICE_NUM);
    return ret;   
}

static void __exit char_exit(void)
{
    int i ;
    for(i = 0; i < DEVICE_NUM; i++)
    {
        cdev_del(&(myCharDevice[i].dev));
        device_destroy(myClass,MKDEV(char_major,(char_minor + i)));
    }
    class_destroy(myClass);
    kfree(myCharDevice);
    unregister_chrdev_region(charId,DEVICE_NUM);

}

module_init(char_init);
module_exit(char_exit);
```
## 杂项设备驱动
上面所说杂项设备是一种特殊的字符设备，这里就可以得到证明了。说它特殊主要是因为它的主设备号已经固定了（10），我们不需要再费心费力为它分配设备号了。因此杂项设备的使用十分方便，操作也十分简单。
描述杂项设备的结构体以及主要的函数：`include/linux/miscdevice.h`
```C
struct miscdevice  
{
	int minor;
	const char *name;
	const struct file_operations *fops;
	struct list_head list;
	struct device *parent;
	struct device *this_device;
	const char *nodename;
	mode_t mode;
};

extern int misc_register(struct miscdevice * misc);
extern int misc_deregister(struct miscdevice *misc);
```
在模块中定义好`struct miscdevice`和`struct file_operations`变量并进行初始化，然后将注册和卸载函数分别放在入口函数`init`和出口函数`exit`中就可以了。
# 总结


<p id="div-border-top-red">显而易见，杂项设备驱动的编写相比于标准字符驱动来说是十分方便的。既然如此，我们为何不尝试使用呢</p>


  
<blockquote class="blockquote-center">完</blockquote>