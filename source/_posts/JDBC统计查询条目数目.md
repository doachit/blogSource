---
title: JDBC统计查询条目数目
date: 2016-06-20 22:18:22
categories: java
tags: [JDBC,mysql]
grammar_cjkRuby: true
---
JDBC中可以执行基本的查询操作，有的时候我们会需要统计符合相关条件条目的数目，但是
JDBC并没有提供相关的API来得到该信息。但是通过下面几种操作能够实现：

# 通过统计ResutSet中条目数目进行操作
```
ResultSet set = stat.executeQuery("select * from tableName");
int countNum = 0;
while(set.next())
{
    countNum++;
}
```
<!-- more -->
# 通过JDBC中的getRow()来得到最后一行的行号来进行查询
```
ResultSet set = stat.executeQuery("select * from tableName");
set.last(); //移动到最后一行
int countNum = set.getRow();//得到最后一行的行号，也就是总的条目信息
set.beforeFirst();//回到第零行，第一行是正式的数据（如果查询到的话）

```
# 通过count语句进行实现
```
ResultSet set = stat.executeQuery("select count(*) from tableName");
int countNum;
if(set.next())
{
    countNum = set.getInt("count(*)");
}
```
[文章参考地址](http://blog.csdn.net/chenzhanhai/article/details/6257066)
本文使用 **小书匠编辑器**发布。