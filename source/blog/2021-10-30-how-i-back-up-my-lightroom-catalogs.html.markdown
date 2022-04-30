---
title: How I back up my Lightroom catalogs
description: A quick writeup on how I keep my Lightroom catalogs backed up.
date: 2021/10/30
author: Guillermo Esteves
---

In general, I keep all my photos in a single Lightroom catalog, organized by date. This catalog, and the photos in it, reside in my Dropbox folder, and is backed up by Time Machine frequently, which gives me a couple levels of redundancy if something were to happen to my laptop. I keep the final, full-size, edited JPGs in iCloud, Flickr, and [my own website](https://www.allencompassingtrip.com), so I have ways to retrieve them if I have to.

However, keeping this one catalog around means it can get pretty huge over time, which is a problem because I don't have unlimited space in either my Dropbox account or my laptop's hard drive. I almost never revisit old photos, so most of the raw files in the catalog are just taking space for no real reason, except in the rare case I need to submit them as part of some photography competition. This means I'm happy to move my raw files out of my laptop to save space, as long as I still have access to them when needed; to do this, I follow this process more or less once a year, and every time I have to re-remember how to do it, so I might as well write it down here in case it's useful to others.

### The TL;DR

* Once a year, export the previous year's photos as a new Lightroom catalog
* Copy that new catalog into _at least_ two external drives
* Compress the new catalog into a DMG image
* Upload the catalog's DMG image to [Amazon Glacier](https://aws.amazon.com/s3/glacier/) for long-term storage, using [Freeze](https://www.freezeapp.net)
* Once the new catalog and its photos are backed up, delete them from the hard drive to reclaim that space

### Step 1: Exporting the past year's photos as a new Lightroom catalog

Once a year, usually at the beginning of the year, I go into Lightroom, select all the photos from the previous year by right-clicking on the year's folder, and export them as a new catalog, ensuring "export negative files" is selected.

![A context menu in Lightroom, with the "export this folder as a catalog" option selected.](blog/2021-10-30-how-i-back-up-my-lightroom-catalogs/export-as-catalog.png)

This creates a new catalog, including all the raw files for all the photos from that year, in a new folder elsewhere on my computer. From there, I copy them to _at least two_ external hard drives, so I have some redundancy if something were to happen to them (ideally one of them should be kept offsite). If I ever need to look at these catalogs, for example to grab the raw files as I mentioned above, I can simply plug in the drive, do what I need to do, then put it away again.

### Step 2: Uploading the new catalog to Amazon Glacier

Next, I upload these catalogs to Glacier for long-term storage. This is optional, but I like the peace of mind of having this as a last resort if I were to lose all my external drives somehow.

The first step is to create a DMG image of the folder containing the new catalog and all its photos, by opening Disk Utility, selecting `File > New Image > Image from Folder`, and selecting the appropriate folder. I leave the default checkboxes checked; I don't think compressing the image does much but I leave that on, and I don't encrypt the image, but you may do so if you want. This will take a while, and at the end I have a `.dmg` file somewhere on my system.

![The Disk Utility app in macOS, with a dialog open to save a new image.](blog/2021-10-30-how-i-back-up-my-lightroom-catalogs/disk-utility.png)

To upload these files to Glacier, I use an app called [Freeze](https://www.freezeapp.net), which makes the process a snap. It requires setting up an AWS user for it with the appropriate permissions to access Glacier (which I will leave as an exercise to the reader). With that user's access key and secret set up in Freeze, I've created a new vault in Glacier to store my catalogs, and then it's a simple process of dragging the DMG files into the vault and waiting for the uploads to complete.

![The Freeze app for macOS, showing a couple of uploads in progress.](blog/2021-10-30-how-i-back-up-my-lightroom-catalogs/freeze.png)

### Step 3: Reclaim hard drive space

Once the catalogs and their photos have been copied to the external drives and uploaded to Glacier, I delete those photos from the main catalog and remove them from my computer to clear up that space. And that's it!

### Caveats

* While I rarely have a need for these older catalogs, I don't want to risk losing them entirely if an external drive dies, which is why I rely on external drives _and_ Glacier.
* However, retrieving files from Glacier, even just to list the contents of the vault, takes _hours_. I'd rather not have to use it, which is why I emphasize copying the catalogs to multiple external drives. They're cheap these days, anyway; I've been using these [Seagate 2TB external drives](https://amzn.to/3pVTSwi) for the past couple of years, with zero issues so far.
* One problem with this strategy is that the process of exporting the previous year's photos as a new catalog effectively copies them, so I need to have enough hard drive space to do that. I've definitely been in a situation where if I put it off too long, I won't have enough space to do it.

That said, this strategy has worked well for me so far, and I feel it strikes a good balance between having access to old photos, keeping them safe, and preserving space on my laptop's hard drive.
