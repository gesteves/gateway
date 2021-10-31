---
title: "Hello, World"
date: 2011-09-19 17:14
description: "After almost four years on Tumblr, I've decided it's time to switch blog platforms. My blog now runs on Octopress and Heroku."
author: Guillermo Esteves 
---

After almost four years on [Tumblr][tumblr], I've decided it's time to switch blog platforms. My blog now runs on [Octopress][octo] and [Heroku][her].

The reason I'm switching, and the reason I was using Tumblr in the first place, are a bit of a long story. I used to have a real blog, one I built myself in 2005 or so, when I was teaching myself Rails, and which I loved and updated frequently. However, a couple of years later, thanks to Venezuela's foreign currency restrictions which forbid us from spending more than US$400 a year in electronic payments, having a self-hosted blog running on paid hosting -- even cheap, shared hosting -- became untenable. Back then I was spending $9 a month at [Rails Playground][rp] to host my blog, which may not sound like a lot, but it added up to $108 a year -- over a quarter of what the venezuelan government allows me to spend on the Internet in a year. So, in 2008, when Tumblr began to take off in popularity, I decided to cancel my hosting plan, scrap my blog, write a small script to import all my content, and switch to Tumblr.

[rp]: http://railsplayground.com/

It had the advantage of not having to worry about servers or hosting costs while being flexible enough to allow me to tinker with the code and design to my heart's content, plus an amazing community that led me to meet some of the best friends I've ever had. However, in the past few months I've become quite dissatisfied with the service and the constant outages and downtime, like [this recent][outage], ongoing issue. I'm also a bit uneasy with the content I post over there, because it's a strange mix of work/professional stuff and personal posts, reblogs, memes, and inside jokes that probably aren't interesting to anyone except my close circle of friends. So I thought it would be better to have a place that's just for [serious business][sb], and leave Tumblr for personal posts, socializing with my friends, and sharing photos of cats. [All-Encompassing Trip][aet] will keep going at its new address, but this will be my primary blog for now.

[sb]: http://gestev.es/AGnN
[outage]: http://staff.tumblr.com/post/10264121525/outage

As for my choice of platform, I chose [Octopress][octo] after reading [Matt Gemmell][legend] [rave about it][legend-octo]. I've always liked the idea of having a “[baked][baked]” blog (i.e. one that's entirely static <abbr>HTML</abbr>), and I've experimented in the past with things like [nanoc][nanoc], but Octopress makes it dead simple to set up, generate, and deploy a static <abbr>HTML</abbr> blog. If you're considering starting a blog, and feel comfortable working in the Terminal, I can't recommend Octopress enough.

[tumblr]: http://www.tumblr.com
[octo]: http://octopress.org
[her]: http://www.heroku.com
[legend]: http://mattgemmell.com
[legend-octo]: http://mattgemmell.com/2011/09/12/blogging-with-octopress/
[aet]: http://tumblr.gesteves.com
[baked]: http://inessential.com/2011/03/16/a_plea_for_baked_weblogs
[nanoc]: http://nanoc.stoneship.org/

There are plenty of advantages to the "baked" approach. Since there are no slow and expensive database calls, it's blazing fast, lighter and more responsive, and it won't fall down the first traffic spike it gets -- not that I'm expecting to get [fireballed][df] or anything, but for me it also means that it's lightweight enough that I can probably get away with running it with a single Heroku dyno for the foreseeable future -- which makes it free. There's also a security argument to be made, since there's no admin interface to hack, or any chance of <abbr>SQL</abbr> injection. I also like that it makes backups really simple: the posts live on my computer, so they get backed up to Time Machine and SuperDuper as part of my regular backup process; my Sites folder is symlinked in my Dropbox folder, so there's a backup there too; and since the posts are also under source control, everything gets committed to my Github repo as well. Finally, migration is trivial, because it's just a bunch of static <abbr>HTML</abbr> files. Just put them on a new server and it'll work. Octopress can even automate the process of copying the files to the server with rsync after writing a post.

[df]: http://daringfireball.net

A few other things of note:

* The theme is mostly built from scratch, based on the design of [my website][web]. Unfortunately, I mostly destroyed all the sensible patterns and defaults [Brandon][imathis] (the creator of Octopress) created for theming it, so I think I'll have to do some work rebuilding them to keep the code more organized. I did keep his awesome port of [Solarized][sol] syntax highlighting, though.
* I modified it for deployment to Heroku. This included, on Brandon's instructions, removing the `public` folder from `.gitignore`, but I also added everything *but* the `public` folder and the config files to `.slugignore`, to keep the slug size as small as possible (it clocks in at 460 KB, vs. 4.4 MB for [my website][web]'s slug); and I added a rake task for Heroku deployment, which is mostly a copy of the default Github one, but pushing to Heroku `master` instead.
* I wanted to use [iA Writer][ia] as my blogging software, so I modified the `new_post` rake task so that it calls `open #{filename}` at the end, which opens the newly created post in the default editor for Markdown files, which I had previously set to Writer.
* I also symlinked the `_posts` folder to the [Writer][ia] and [Elements][ele] folders in my Dropbox, so I can theoretically write posts from my iPad and iPhone, although I'd have to <abbr>SSH</abbr> into my computer to actually publish them.
* I'm trying to simplify the process of creating new posts and deploying to Heroku, and integrate it better to the OS. I'm currently trying to figure out how to add the rake tasks to OS X's Services menu, to make it easier to publish posts after writing them. I also replaced some of the `puts` calls in the Rakefile with calls to `growlnotify`, to get nice Growl notifications on successful deploys and whatnot.
* I still haven't decided whether or not I want comments here, or if I want to use [Disqus][disqus] or [Facebook Comments][fbc]. In the meantime, you can [tweet @gesteves][tweet] with any comments.
* I didn't import any of the old content from Tumblr; I couldn't figure out a good way to do it without breaking a ton of links, since Tumblr's permalink format doesn't match Octopress's. I thought about modifing Octopress's permalinks and work something out using my local backup of Tumblr, but instead I opted for a clean break and a fresh start, using a bit of [Sinatra][sinatra] code to 301-redirect any traffic looking for a Tumblr permalink to my Tumblr's [new domain][aet].

[web]: http://www.gesteves.com
[imathis]: https://twitter.com/#!/imathis
[ia]: http://www.iawriter.com/
[sol]: http://ethanschoonover.com/solarized
[ele]: http://www.secondgearsoftware.com/elements/
[disqus]: http://disqus.com/
[fbc]: https://developers.facebook.com/docs/reference/plugins/comments/
[tweet]: https://twitter.com/intent/tweet?text=%40gesteves%20
[sinatra]: http://www.sinatrarb.com/

Anyway, I'm not entirely sure how much or how often I'll write here -- Twitter & Tumblr seem to have atrophied my ability to write more than 140 characters at a time, and writing this post took longer than I care to admit -- but I do hope to at least comment on interesting web design & development resources I find, in the style of [Assaf Arkin][assaf]'s "Rounded Corners" series -- which I love -- and maybe get back in the habit of writing well enough to, you know, express, like, opinions and stuff. Wish me luck, and thanks for reading.

[assaf]: http://labnotes.org/