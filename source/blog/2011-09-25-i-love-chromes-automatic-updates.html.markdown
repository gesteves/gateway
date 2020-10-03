---
title: "I love Chrome’s automatic updates"
description: "Older versions of Chrome virtually disappear as soon as a new version is released, which is nice."
date: 2011/09/25
author: Guillermo Esteves
---

Last night I signed up for [Clicky Web Analytics][clicky], and looking around their site I saw that they offer [market share][market] stats for the major browsers (<abbr>IE</abbr>, Chrome, Safari, Firefox, and Opera,) both in general, and split by browser version. Looking at Chrome's stats, I noticed something interesting in the graph:

[clicky]: http://getclicky.com/239148
[market]: http://getclicky.com/marketshare/

![Chrome market share](blog/2011-09-25-i-love-chromes-automatic-updates/chrome-market-share.png)

Thanks to Chrome's silent automatic updates, as soon as a new version is released, the previous one virtually disappears in a matter of days! I'm sure there are valid arguments against updating software automatically and silently, for example at organizations that need to control what software their employees use, or that need to test existing applications in new browser versions before deploying them; but from a developer's point of view I think it's awesome, because for all intents and purposes there's only one version of Chrome -- the current one. Since older versions aren't a big concern, testing in Chrome becomes simpler and easier: there's no need to hunt down and keep multiple versions for testing.

Compare to Internet Explorer, where the four most recent versions coexist, so if it represents a major portion of your visits (and it probably does,) then you'll have to support at least two of them: Internet Explorer 8, for the large number of people still running Windows XP; and 9, for those running Windows Vista and 7. Unfortunately, unless dropping XP and Vista is an option, you'll probably have to keep supporting them even after Internet Explorer 10 comes out, since [it won't support Windows Vista][ie10vista].

![Internet Explorer market share](blog/2011-09-25-i-love-chromes-automatic-updates/internet-explorer-market-share.png)

[ie10vista]: http://www.pcmag.com/article2/0,2817,2383640,00.asp#fbid=9CphUBgOJbN

Safari's market share behaves a bit like <abbr>IE</abbr>'s, inasmuch as it doesn't automatically update and the newest version coexists with the older one, but remarkably Safari 5.1 has already overtaken the previous version, just a month after its release with the launch of Lion. Still, until 5.0 is gone, testing in it might be problematic unless you have an older Mac nearby, or a Snow Leopard Server disc you can install in VMware Fusion or Parallels.

![Safari market share](blog/2011-09-25-i-love-chromes-automatic-updates/safari-market-share.png)

<aside><p>If Firefox 3.6 is a concern for you, and you need or want to test in it, you can <a href="http://www.mozilla.org/en-US/firefox/all-older.html">download it here</a>.</p></aside>

Firefox, meanwhile, behaves in a combination of both ways. After Firefox 4, which introduced automatic updates, it behaves like Chrome, with the previous version dropping off after a new release; but with a good number of users still on version 3.6, which didn't have automatic updates.

![Firefox market share](blog/2011-09-25-i-love-chromes-automatic-updates/firefox-market-share.png)

And Opera… oh, who cares, I'm pretty sure Opera's market share is composed entirely of developers testing their sites in Opera.

Anyway, knowing that I can stop worrying about testing in older versions of Chrome (and to a much lesser degree, Firefox and Safari) personally makes my job much easier, but as usual, your mileage may vary. Let your own browser stats be your guide.
