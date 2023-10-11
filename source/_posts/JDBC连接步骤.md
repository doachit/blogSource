---
title: JDBC连接步骤 
date: 2016-06-21 22:18:22
categories: java
tags: [JDBC,数据库,JAVA]
grammar_cjkRuby: true
---
JDBC全称为java database connection ，即java数据库连接，JDBC是连接Java应用程序和底层数据库的桥梁，示意图如下:
![JDBC示意图](/img/jdbc.jpg)
JDBC的连接过程一般是下面几个步骤;
### 加载驱动
```
Class.forName("com.mysql.jdbc.Driver"); 
```
<!-- more -->
### 建立连接
```
conn = (Connection) DriverManager.getConnection(link,user,password);
```
### 创建执行SQL语句的Statement
```java
stat = (Statement) conn.createStatement(); 
```
### 执行SQL语句，对查询的返回的结果进行处理
```java
ResultSet set = stat.executeQuery("select * from tableName");`
while(set.next())`
{
    //这是两种取数的方法
    set.getString(1);
    set.getString("name");
}
```
### 关闭资源
要按时释放资源，否则可能会导致资源少儿死机。一般是关闭ResultSet，Statement，Connection的连接。
```
//注意要捕获异常
if(set != null)
{
    set.close();
}
if(stat != null)
{
    stat.close();
}
if(conn != null)
{
    conn.close();
}
```
# 一个完整的实例
```
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;

import com.mysql.jdbc.Connection;
import com.mysql.jdbc.Statement;

public class Test {

	public static void main(String[] args) {
		String driver = "com.mysql.jdbc.Driver";
		String link = "jdbc:mysql://localhost/student";//student 是表名
		String user = "user";
		String password = "password";
		Connection conn = null;
		Statement stat = null;
		ResultSet set = null;
		
		
		try {
			Class.forName(driver);//加载驱动
			
			conn = (Connection) DriverManager.getConnection(link,user,password);//建立连接
		 
			stat = (Statement) conn.createStatement();//创建执行语句的Statement
			
			set = stat.executeQuery("select * from student");//执行查询语句
			
			System.out.println("\t姓名\t性别\t科目一\t科目二");
			
			while(set.next())//打印输出查询结果
			{
				System.out.println("\t" + set.getString(1) + "\t" + set.getString(2) + "\t"
								    + set.getFloat(5) + "\t" +set.getFloat(6));
			}
		} catch (SQLException e) 
		{
			e.printStackTrace();
		}
		catch (ClassNotFoundException e) 
		{
			e.printStackTrace();
		}finally //在finally中关闭资源
		{
			try
			{
				if(set != null)
				{
					set.close();
				}
			}catch (SQLException e)
			{
				e.printStackTrace();
			}
			
			try
			{
				if(stat != null)
				{
					stat.close();
				}
			}catch (SQLException e)
			{
				e.printStackTrace();
			}
			
			try
			{
				if(conn != null)
				{
					conn.close();
				}
			}catch (SQLException e)
			{
				e.printStackTrace();
			}
		}

		
	}

}

```
本文使用 **小书匠编辑器**发布。