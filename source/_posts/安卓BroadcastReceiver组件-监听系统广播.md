---
title: 安卓BroadcastReceiver组件-监听系统广播 
date: 2016-05-23 22:18:22
categories: Android
tags: [安卓,BroadcastReceiver,系统广播]
grammar_cjkRuby: true
---



安卓系统在运行过程中，会不断的发送一些广播信息，比如电量不足，时区改变，有来电或者短信等。应用程序通过监听这些广播信息就能够得到系统的一些状态。
<!-- more -->
>广播接收器想要监听系统广播需要注册，注册的方式有两种，第一种是在java代码中注册，另一种是在AndroidManifest.
xml文件中注册。对于这两种方法来说，前者称之为动态注册，后者称之为静态注册。

----------
下面通过两个例子来介绍这两种方式的使用方法：
# 1.动态注册-监听网络连接
在网络连接状态发生改变时，系统会发出一个`android.net.conn.CONNECTIVITY_CHANGE`的action，我们需要在代码中添加对应的filter来响应即可。
```java
public class MainActivity extends AppCompatActivity {
    private IntentFilter intentFilter;//
    private NetworkChangeReceiver networkChangeReceiver;//

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        intentFilter = new IntentFilter();
        intentFilter.addAction("android.net.conn.CONNECTIVITY_CHANGE");//添加filter
        networkChangeReceiver = new NetworkChangeReceiver();
        registerReceiver(networkChangeReceiver, intentFilter);//注册该接收器
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unregisterReceiver(networkChangeReceiver);//退出时取消该广播接收器
    }

    class NetworkChangeReceiver extends BroadcastReceiver {
        @Override
        public void onReceive(Context context, Intent intent) {

                Toast.makeText(context, "network change!", Toast.LENGTH_SHORT).show();//发现网络状态改变
        }
    }
}
```

----------

# 2.静态注册-实现应用开机启动
**首先**我们需要有能开机启动的权限。
```
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```
**接着**新建一个class为`BootCompletedReceiver`,其继承自BroadcastReceiver：
```java
public class BootCompletedReceiver extends BroadcastReceiver
{
    @Override
    public void onReceive(Context context,Intent intent){
        Toast.makeText(context,"Boot completed!".Toast.LENGTH_LONG).show();
    }
}
```
就像activity一样，广播接收器也需要在AndroidManifest.xml文件中注册。对于开机启动来说，系统对外发送的intent的action为BOOT_COMPLETED。
**然后**我们注册该广播接收器：
```
<application
    ...
    <receiver android:name=".BootCompletedReceiver">
        <intent-filter>
            <action android:name="android.intent.action.BOOT_COMPLETED"/>
        </intent-filter>
    </receiver>
    ...
</application>

```
这样就实现了开机启动，开机之后会显示`Boot completed!`的信息来提示应用已经启动。


----------


本文使用 **小书匠编辑器**发布。