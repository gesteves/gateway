---
title: "Fixing Web Sharing after a Time Machine restore"
description: "Restoring Mac OS X from a Time Machine backup breaks Web Sharing. Here’s how to fix it."
date: 2008/06/20
author: Guillermo Esteves
tags: Software, Bugblogging
---

Has anyone had any problems lately with Web Sharing not working at all? Say, after restoring from Time Machine? I just noticed it a few days ago, but didn't pay much attention; after all I just use the Mongrel bundled with Rails. But today I was checking the Console and noticed this:

    Jun 20 12:18:46 Delta org.apache.httpd[11920]: (2)No such file or directory: httpd: could not open error log file /private/var/log/apache2/error_log.
    Jun 20 12:18:46 Delta org.apache.httpd[11920]: Unable to open logs
    Jun 20 12:18:46 Delta com.apple.launchd[1] (org.apache.httpd[11920]): Exited with exit code: 1

Crap. Of course. I remembered that a few weeks earlier I had replaced my PowerBook's aging 80GB hard drive with a brand new 160GB one, and restored my Mac OS X installation with Time Machine. As [James Duncan Davidson](http://duncandavidson.com) notes in his [Restoring from Time Machine](http://duncandavidson.com/2008/01/restoring-from-time-machine.html) article, Time Machine automatically excludes a bunch of stuff like caches and logs, so Apache's log directory is not recreated during a restore, and that caused it to crash and burn.

So, anyway, to fix it, just open up the terminal and type `sudo mkdir /private/var/log/apache2`. I hope this helps someone with the same problem.
