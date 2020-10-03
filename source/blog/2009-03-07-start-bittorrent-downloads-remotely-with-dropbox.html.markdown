---
title: "Start BitTorrent downloads remotely with Dropbox"
description: "Here’s a quick way to start BitTorrent downloads remotely, if you’re using Dropbox and Transmission."
date: 2009/03/07
author: Guillermo Esteves
---

Here’s a quick way to start BitTorrent downloads remotely, if you’re using [Dropbox][dropbox]. First, make sure Dropbox is installed in the computer where you regularly download your torrents, probably your main computer at home. For those not using Dropbox, you can get an account [here][dropbox]. You’ll have to download a small application, which creates a “Dropbox” folder in your “My Documents” folder in Windows or in your “Home” folder in OS X. Dropbox keeps that folder synchronized across all the computers where you have installed it, so that if you move a file into that folder, it will show up on all the other computers. You can also access and upload files via Dropbox’s web interface.

Now, most BitTorrent clients have an option to automatically add torrents copied on a certain folder. In [Transmission][transmission], it’s in preferences, in the “transfers” tab. Check the <q>Watch for torrent files in</q> option. Optionally, check the <q>Trash original torrent files</q> so your folder doesn’t fill up with old `.torrent` files.

![Transmission preferences](blog/2009-03-07-start-bittorrent-downloads-remotely-with-dropbox/84438959_1.png)

In [µTorrent][utorrent], the option is in the preferences (the cog icon in the toolbar), under “directories.” Check <q>Automatically load `.torrents` from</q> and optionally, <q>Delete loaded `.torrents`.</q>

![Transmission preferences](blog/2009-03-07-start-bittorrent-downloads-remotely-with-dropbox/84438959_2.png)

What you want to do is set those options to watch your Dropbox folder (or a folder inside your Dropbox, if you want to keep things tidy) for new `.torrents`, so they’ll start downloading automatically when a new file appears. _Do not_, however, set your client to save the resulting download into your Dropbox folder. Save them elsewhere.

Now as long as you keep Dropbox and BitTorrent running, you can start torrents remotely. All you have to do is upload `.torrent` files to the Dropbox folder from wherever you are, using the web interface, and it should start downloading almost immediately on the other computer. I started doing this at the office, because for some reason I can’t use Transmission’s web UI from there, and it’s worked for me without a hitch; by the time I get home, my downloads are usually ready. Give it a shot, and let me know what you think.

## Bonus: Move your files and start Transmission with Automator

When I first wrote this last year, I forgot two critical issues. First, if I tell my computer to watch my Dropbox for torrent files, it means that when I’m at home I’ll have to move the torrent files there myself, or start the downloads manually, because by default they’re saved to the Downloads folder. That’s annoying. And second, if Transmission is not running, then saving the torrent files to Dropbox is not going to be of much help. Well, you can solve both problems in Mac OS X 10.6 with a couple of Automator folder actions.

1.  Open Automator. In the initial “choose a template for your workflow” dialog, select “folder action”.
2.  In the “Folder Action receives files and folders added to” dropdown at the top of the window, select your Downloads folder, or the folder where you have set your browser to save your downloaded files.
3.  In the actions library to the left, select “Files <abbr title="and">&</abbr> Folders” and add a “Filter Finder Items” action. Set the conditions to “file extension” “is” “torrent”.
4.  Add a “Move Finder Items” action. Set it to move the files to the folder in your Dropbox you told your BitTorrent client to watch.
5.  From “Utilities”, add a “Launch Application” action, and tell it to launch Transmission, or whatever BitTorrent app you use.
6.  Save your workflow.

Your workflow should look like this:

![](blog/2009-03-07-start-bittorrent-downloads-remotely-with-dropbox/84438959_3.png)

When you download a torrent file locally, it will automatically move it to Dropbox, where Transmission will catch it and start the download. That takes care of the case where you download the torrent locally, but you need a second automator action to start Transmission when you add a torrent to Dropbox remotely:

1.  Create another Automator workflow. Again, make it a Folder Action, but this time tell it to watch the second folder, the one inside Dropbox where you’re moving the torrent files.
2.  In the actions library to the left, select “Files <abbr title="and">&</abbr> Folders” and add a “Filter Finder Items” action. Set the conditions to “file extension” “is” “torrent”.
3.  From “Utilities”, add a “Launch Application” action, and tell it to launch Transmission, or whatever BitTorrent app you use.
4.  Save the workflow.

Boom. Done. Now, when a torrent file appears in your Dropbox, either because you uploaded it remotely or because the first Automator folder action moved it from the Downloads folder, your BitTorrent app will automatically launch and start the download.

[dropbox]: https://www.getdropbox.com/referrals/NTE4MjI2OQ
[transmission]: http://www.transmissionbt.com/
[utorrent]: http://www.utorrent.com/
