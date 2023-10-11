---
title: linux平台驱动模型框架
date: 2017-05-01 10:09:42
categories: linux驱动
tags: [linux驱动] 
---
在这么多年的学习生涯中，我们知道要想尽快的掌握一部分知识不是去搞题海战术，而是要总结出很多题目背后的知识点进行巩固，以不变应万变。我们把这种方法称之为抽象，这也是最有效的学习方法，同样针对linux中纷繁复杂，千差万别的驱动学习，也是如此。
# 总线 设备 驱动
总线，设备和驱动是linux驱动所涉及到的三方。设备和驱动都挂载在总线上，并且由总线进行管理。设备和驱动对应，每一个设备都有对应的驱动，驱动也是如此。不管哪一方先挂载到总线上，总线都会去遍历另一方来完成两者的匹配（`match()`），匹配成功后便会调用驱动的`probe()`方法来完成设备的初始化等操作。
<!-- more -->
## 三者之间的代码描述：
```C
bus
------------------------------
struct klist klist_devices;     //记录bus上挂载的devices
struct klist klist_drivers;     //记录bus上挂载的drivers

device
------------------------------
struct bus_type	*bus;           //记录当前device挂载的总线
struct device_driver *driver;	//记录当前device绑定的driver


device_driver
------------------------------
struct bus_type		*bus;       //记录当前driver挂载的总线
struct klist klist_devices;     //记录当前driver支持的设备，一个driver可以支持多个不同的设备。
```

# platfrom平台驱动
前面所说的bus_type其实是所有总线的一种抽象，因此不管是实体总线比如I2C,SPI，亦或是虚拟总线platform都是由bus_type衍生而来。下面就来探究一下platform总线。
```C
struct bus_type platform_bus_type = 
{	
	.name		= "platform",
	.dev_attrs	= platform_dev_attrs,
	.match		= platform_match,
	.uevent		= platform_uevent,
	.pm		= &platform_dev_pm_ops,
};
```
platform总线的注册流程：
```C
start_kernel(void)——>rest_init()——>kernel_init()——>do_basic_setup()
——>driver_init(void)——>platform_bus_init(void)——>device_register()——>bus_register()
```
linux中从始至终都秉承着一切皆文件的思想。对于总线来讲也是如此，无论是实体总线或者是虚拟总线都会被当作设备来进行注册。从这个流程来看，platform的注册要先注册一个设备，然后在注册总线，总线是以设备的形式存在的。
## platform_device
platform_device其实是对上面的device结构体的一种封装，其核心还是device。platform_device_register函数是用来注册平台设备的，具体调用流程如下所示：
```C
platform_device_register()
{
    platform_device_add()
    {
        ...
        device_add()
        {
            ...
            bus_add_device() //添加设备到bus上
            {
                ...
                klist_add_tail(&dev->p->knode_bus, &bus->p->klist_devices);//添加设备到klist中去
                ...
            }
            
            ...
            
            bus_probe_device()  //设备添加成功之后进行匹配驱动
            {
                device_attach()
                {
                    ...
                    //遍历来寻找驱动，并与之绑定
                    bus_for_each_drv(dev->bus, NULL, dev, __device_attach);
                    ...
                }
            }
            ...
        }
        ...
    }
}
```
通过platform_device_register来注册平台设备，然后会调用platform_device_add，紧接着调用device_add。在device_add中会涉及到一些核心的部分：设备通过bus_add_device添加到总线上，添加成功之后就会通过bus_probe_device来探测driver，最后通过device_attach函数实现设备和驱动的绑定。
## platform_driver
和platform_device一样，platform_driver也是device_driver的封装，platform_driver_register是用来注册驱动的。
```C
struct platform_driver {
	int (*probe)(struct platform_device *);
	int (*remove)(struct platform_device *);
	void (*shutdown)(struct platform_device *);
	int (*suspend)(struct platform_device *, pm_message_t state);
	int (*resume)(struct platform_device *);
	struct device_driver driver;
            //-------------------------------------------------
            //device_driver结构体中的函数
                int (*probe) (struct device *dev);
                int (*remove) (struct device *dev);
                void (*shutdown) (struct device *dev);
                int (*suspend) (struct device *dev, pm_message_t state);
                int (*resume) (struct device *dev);
            //-------------------------------------------------
	const struct platform_device_id *id_table;
};

int platform_driver_register(struct platform_driver *drv)
{
	drv->driver.bus = &platform_bus_type;
	if (drv->probe)
		drv->driver.probe = platform_drv_probe;
	if (drv->remove)
		drv->driver.remove = platform_drv_remove;
	if (drv->shutdown)
		drv->driver.shutdown = platform_drv_shutdown;

	return driver_register(&drv->driver);
}
```
可以看出device_driver中的几个函数和platform_driver中的几个函数是一一对应的。driver_register函数首先就把两者之间的函数进行一一映射，具体调用如下所示：
```
driver_register()
{
    ...
    bus_add_driver()    //将驱动添加到总线上
    {
        ...
        driver_attach()
        {
            bus_for_each_dev(drv->bus, NULL, drv, __driver_attach);//遍历来寻找设备,并与之绑定
        }
        klist_add_tail();   //添加驱动到klist中去
        ...
    }
    ...
}
```
# match与probe
前面我们也说过，设备与驱动匹配`match()`成功之后就会调用`probe()`函数来完成设备的初始化等操作，那么整个流程是什么样的呢？
首先我们看一下bus和platform的结构体
```C
struct bus_type {
	const char		*name;
	struct bus_attribute	*bus_attrs;
	struct device_attribute	*dev_attrs;
	struct driver_attribute	*drv_attrs;

	int (*match)(struct device *dev, struct device_driver *drv);
	int (*uevent)(struct device *dev, struct kobj_uevent_env *env);
	int (*probe)(struct device *dev);
	int (*remove)(struct device *dev);
	void (*shutdown)(struct device *dev);

	int (*suspend)(struct device *dev, pm_message_t state);
	int (*resume)(struct device *dev);

	const struct dev_pm_ops *pm;

	struct subsys_private *p;
};

struct bus_type platform_bus_type = {
	.name		= "platform",
	.dev_attrs	= platform_dev_attrs,
	.match		= platform_match,
	.uevent		= platform_uevent,
	.pm		= &platform_dev_pm_ops,
};
```
查看前面的driver结构体和bus结构体我们不难发现bus中存在match和probe函数，driver中也存在一个probe函数。具体如何执行我们下面接着看就明白了。
我们都知道对于设备和驱动来讲，不管先添加哪一方，总线都回去遍历另一方来实现两者的匹配操作。在上面的添加设备和驱动的流程中我们也发现了上述的匹配操作主要是通过`__device_attach`和`__driver_attach`来进行的，下面来具体看一下这两个函数。
```C
//遍历驱动来绑定设备的函数
static int __device_attach(struct device_driver *drv, void *data)
{
	struct device *dev = data;

	if (!driver_match_device(drv, dev))
		return 0;

	return driver_probe_device(drv, dev);
}

//遍历设备来绑定驱动的函数
static int __driver_attach(struct device *dev, void *data)
{
	struct device_driver *drv = data;

	if (!driver_match_device(drv, dev))
		return 0;

	if (dev->parent)	/* Needed for USB */
		device_lock(dev->parent);
	device_lock(dev);
	if (!dev->driver)
		driver_probe_device(drv, dev);
	device_unlock(dev);
	if (dev->parent)
		device_unlock(dev->parent);

	return 0;
}
```
很显然上面的两个过程基本上是一致的，主要是`driver_match_device`和`driver_probe_device`这两个函数,那么我们就在深入探究一番：
```C
static inline int driver_match_device(struct device_driver *drv,
				      struct device *dev)
{
	return drv->bus->match ? drv->bus->match(dev, drv) : 1;
}
```
哈哈，找到了。功夫不负有心人呀，这就是我们想要的~意思已经很明白了，如果bus的match函数存在的话就调用咯，这个就是我们的`platform_match`函数。
下面在看另外一个函数`driver_probe_device`:
```C
int driver_probe_device(struct device_driver *drv, struct device *dev)
{
    ...
        static int really_probe(struct device *dev, struct device_driver *drv)
        {
            ...
            
            if (dev->bus->probe)    //如果总线的probe函数存在就调用总线的probe函数
            {
                ret = dev->bus->probe(dev);
                if (ret)
                    goto probe_failed;
            } else if (drv->probe)  //否则就调用driver的probe函数
            {
                ret = drv->probe(dev);
                if (ret)
                    goto probe_failed;
            }    
            
            ...
        }
    ...
}
```
上面的代码意思也很明了，如果总线的probe函数存在就调用总线的probe函数，否则就调用driver的probe函数。通过上面的platform的定义来看，很明显总线的probe函数没有定义，那么自然调用的就是driver中的probe函数了。

# 总结
总线分别维护两条链表来记录当前挂载的设备和驱动。不论是设备和驱动哪一方先注册，总线都会遍历另一方来进行匹配（match），匹配成功后会调用driver的probe函数来进行相应的设备初始化等操作。

<blockquote class="blockquote-center"> # 完结</blockquote>
  