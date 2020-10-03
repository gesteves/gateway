---
title: "How to get a D-Link DWL-G650+ Wi-Fi adapter to work in Ubuntu Linux 6.06"
description: "A few days ago I installed the latest version of Ubuntu Linux (version 6.06, Dapper Drake) on my old Compaq Presario 1200 laptop…"
date: 2006/06/08
author: Guillermo Esteves
---

A few days ago I installed the latest version of [Ubuntu Linux](http://www.ubuntu.com/) (version 6.06, Dapper Drake) on my old Compaq Presario 1200 laptop. The installation went smoothly, and Ubuntu runs beautifully, considering it’s an old 800MHz Celeron. Except for one small issue: My D-Link DWL-G650+ 802.11g cardbus adapter wouldn’t work. The status <acronym title="Light Emitting Diode">LED</acronym>s would come on, and the adapter was properly detected by the <abbr title="Operating System">OS</abbr>, but I couldn’t manage to get an <abbr title="Internet Protocol">IP</abbr> from the router. After looking around in Google for a few minutes, I found [this website](https://launchpad.net/distros/ubuntu/+source/linux-source-2.6.15/+bug/30766), which explained that:

> As in the summary, acx111-based d-link dwl-g650+ does not work with the default firmware. It works with 1.2.1.34 (tiacx111c16) - this is the firmware recommended (as the better of the only two working) on acx100 development website - see [http://acx100.sourceforge.net/wiki/Firmware](http://acx100.sourceforge.net/wiki/Firmware)

According to the comments section in that page, there are a few ways to fix this, and I’m going to describe two of them. I’m writing this mostly as a reminder for myself since I’ll probably have to do it again next week after I replace the 10GB hard drive in the Compaq with a new 60GB one, but I thought this might be useful to somebody else.

## Solution 1

This first solution involves deleting `tiacx111c16` from `/lib/firmware/[kernel version]/acx/default`, which links to `/lib/firmware/[kernel version]/acx/2.3.1.31/tiacx111c16` (the broken firmware), and replace it with a link to `/lib/firmware/[kernel version]/acx/1.2.1.34/tiacx111c16` (the working one). To do this open a terminal window and type:

    sudo rm /lib/firmware/[kernel version]/acx/default/tiacx111c16

Replace [kernel version] with your kernel version, obviously. The system will ask you for your password. Enter it. Now type:

    sudo ln -s /lib/firmware/[kernel version]/acx/1.2.1.34/tiacx111c16 /lib/firmware/[kernel version]/acx/default/tiacx111c16

Eject the card, reinsert it, and that’s it. It should be working properly now.

Note: To find out your kernel version, type `echo `uname -r`` at the terminal.

## Solution 2

I think this solution is easier, but you’ll have to reboot your PC. Again, open a terminal, and type:

    sudo pico /etc/modprobe.d/options

Your system will ask your password; provide it. Now add the following line to the file you’re editing:

    options acx firmware_ver=1.2.1.34

Press <kbd>Control+x</kbd> to exit, and press <kbd>Y</kbd> to save the changes. Reboot the computer, and you’re done.

I think that’s it. Feel free to comment if you have any observations or corrections to make.
