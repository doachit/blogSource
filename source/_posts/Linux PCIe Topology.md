---
title: PCIe 拓扑结构
tags: [Linux,PCIe]
date: 2023-06-03 07:18:22
categories: PCIe
comments : true
---
Linux下查看当前的PCI拓扑图，得到的结果如下所示： 
```
root@dell:~# lspci -t
-[0000:00]-+-00.0
           +-01.0-[01]--+-00.0
           |            \-00.1
           +-02.0
           +-03.0
           +-14.0
           +-16.0
           +-1a.0
           +-1b.0
           +-1c.0-[02]--
           +-1c.1-[03-04]----00.0-[04]--
           +-1c.4-[05]----00.0
           +-1d.0
           +-1f.0
           +-1f.2
           \-1f.3
```
<!-- more -->
你也可以加上-v来查看更多的具体信息：
```
root@dell:~# lspci -tv
-[0000:00]-+-00.0  Intel Corporation 4th Gen Core Processor DRAM Controller
           +-01.0-[01]--+-00.0  Intel Corporation I350 Gigabit Network Connection
           |            \-00.1  Intel Corporation I350 Gigabit Network Connection
           +-02.0  Intel Corporation Xeon E3-1200 v3/4th Gen Core Processor Integrated Graphics Controller
           +-03.0  Intel Corporation Xeon E3-1200 v3/4th Gen Core Processor HD Audio Controller
           +-14.0  Intel Corporation 8 Series/C220 Series Chipset Family USB xHCI
           +-16.0  Intel Corporation 8 Series/C220 Series Chipset Family MEI Controller #1
           +-1a.0  Intel Corporation 8 Series/C220 Series Chipset Family USB EHCI #2
           +-1b.0  Intel Corporation 8 Series/C220 Series Chipset High Definition Audio Controller
           +-1c.0-[02]--
           +-1c.1-[03-04]----00.0-[04]--
           +-1c.4-[05]----00.0  Samsung Electronics Co Ltd NVMe SSD Controller PM173X
           +-1d.0  Intel Corporation 8 Series/C220 Series Chipset Family USB EHCI #1
           +-1f.0  Intel Corporation Q87 Express LPC Controller
           +-1f.2  Intel Corporation SATA Controller [RAID mode]
           \-1f.3  Intel Corporation 8 Series/C220 Series Chipset Family SMBus Controller
```
从上面的拓扑结构中可以看出，只有一个domain，然后bus 00下面挂载了多个设备。
- **普通设备**：00.0、02.0、03.0、14.0、16.0、1a.0、1b.0、1d.0、1f.0-3 
- **桥设备**：01.0、1c.0-4
其中01.0桥设备扩展出bus 01，bus 01下面挂载了一个多Function设备；1c.0 桥设备扩展出bus 02，但是上面没有挂载设备。

当然上面1c.1桥设备的连接还是很奇怪，看一下==/sys/bus/pci/devices==中的设备连接以及lspci的结果：
```
lrwxrwxrwx 1 root root 0 Mar 30 13:11 0000:01:00.0 -> ../../../devices/pci0000:00/0000:00:01.0/0000:01:00.0/
lrwxrwxrwx 1 root root 0 Mar 30 13:11 0000:01:00.1 -> ../../../devices/pci0000:00/0000:00:01.0/0000:01:00.1/
lrwxrwxrwx 1 root root 0 Mar 30 13:11 0000:03:00.0 -> ../../../devices/pci0000:00/0000:00:1c.1/0000:03:00.0/
lrwxrwxrwx 1 root root 0 Mar 30 13:31 0000:05:00.0 -> ../../../devices/pci0000:00/0000:00:1c.4/0000:05:00.0/

//lspci的结果
root@dell:~# lspci
00:00.0 Host bridge: Intel Corporation 4th Gen Core Processor DRAM Controller (rev 06)
00:01.0 PCI bridge: Intel Corporation Xeon E3-1200 v3/4th Gen Core Processor PCI Express x16 Controller (rev 06)
00:02.0 VGA compatible controller: Intel Corporation Xeon E3-1200 v3/4th Gen Core Processor Integrated Graphics Controller (rev 06)
00:03.0 Audio device: Intel Corporation Xeon E3-1200 v3/4th Gen Core Processor HD Audio Controller (rev 06)
00:14.0 USB controller: Intel Corporation 8 Series/C220 Series Chipset Family USB xHCI (rev 04)
00:16.0 Communication controller: Intel Corporation 8 Series/C220 Series Chipset Family MEI Controller #1 (rev 04)
00:1a.0 USB controller: Intel Corporation 8 Series/C220 Series Chipset Family USB EHCI #2 (rev 04)
00:1b.0 Audio device: Intel Corporation 8 Series/C220 Series Chipset High Definition Audio Controller (rev 04)
00:1c.0 PCI bridge: Intel Corporation 8 Series/C220 Series Chipset Family PCI Express Root Port #1 (rev d4)
00:1c.1 PCI bridge: Intel Corporation 8 Series/C220 Series Chipset Family PCI Express Root Port #2 (rev d4)
00:1c.4 PCI bridge: Intel Corporation 8 Series/C220 Series Chipset Family PCI Express Root Port #5 (rev d4)
00:1d.0 USB controller: Intel Corporation 8 Series/C220 Series Chipset Family USB EHCI #1 (rev 04)
00:1f.0 ISA bridge: Intel Corporation Q87 Express LPC Controller (rev 04)
00:1f.2 RAID bus controller: Intel Corporation SATA Controller [RAID mode] (rev 04)
00:1f.3 SMBus: Intel Corporation 8 Series/C220 Series Chipset Family SMBus Controller (rev 04)
01:00.0 Ethernet controller: Intel Corporation I350 Gigabit Network Connection (rev 01)
01:00.1 Ethernet controller: Intel Corporation I350 Gigabit Network Connection (rev 01)
03:00.0 PCI bridge: Texas Instruments XIO2001 PCI Express-to-PCI Bridge
05:00.0 Non-Volatile memory controller: Samsung Electronics Co Ltd NVMe SSD Controller 
```
可以看到1c.1下面接了一个设备是03:00.0，这是一个PCI Bridge设备，扩展出了bus 04，上面没有挂载其它设备。

在网上也查到了这种奇怪拓扑的解释：
- [command line - How to interpret lspci -tvv output - Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/505605/how-to-interpret-lspci-tvv-output)
- [linux - How to understand lspci tree format? - Super User](https://superuser.com/questions/1375202/how-to-understand-lspci-tree-format)
总之按我自己理解的意思是1c.1是一个桥设备，它以及它的child扩展出了多个连续的总线，所以用[]包围起来，在本例中，1c.1扩展出bus 03 ，bus 03上面连接了03:00.0，然后又扩展出来了一个bus 04，所以对于1c.1来说后面就扩展出来了两条总线。

还看到了更复杂的：
```
 +-[0000:3a]-+-00.0-[3b-3d]----00.0-[3c-3d]----03.0-[3d]----00.0  Intel Corporation Ethernet Connection X722
 |           +-05.0  Intel Corporation Sky Lake-E VT-d
```
3a:00.0后面扩展出3b-3d的总线，这些总线是由两个PCI Bridge设备通过两级扩展得来的，可能是3b:00.0扩展了bus 3c，第二级3c:00.0扩展了bus 3d，最终3d总线连接了一个3d:00.0的Ethernet设备。