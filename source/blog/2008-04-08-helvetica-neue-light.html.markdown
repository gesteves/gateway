---
title: "Helvetica Neue Light"
description: "I’ve rebuilt the opening crawl for Star Wars Episode IV using only HTML and CSS"
date: 2008/04/08
author: Guillermo Esteves
---

Some of my recent visitors might have noticed that the current version of this site uses [Helvetica Neue Light](http://www.linotype.com/12757/neuehelvetica45light-font.html "linotype.com | Neue Helvetica 45 Light")<sup id="r1-080408">[1](#fn1-080408)</sup> for almost all the text, a look inspired by the beautiful pages of [Panic](http://www.panic.com/ "panic.com | Panic")’s products. As reference, here’s a screenshot of part of [CandyBar](http://www.panic.com/candybar/ "panic.com | CandyBar 3")’s website:

![Partial screenshot of CandyBar's website.](blog/2008-04-08-helvetica-neue-light/36097597_1.png)

Pretty, huh? After snooping around their <abbr title="Cascading Style Sheets">CSS</abbr> I saw they’re using the following declaration for the body text:

<pre>font-family: "HelveticaNeue-Light", Helvetica, Arial,
             sans-serif;
</pre>

I thought this seemed like a slightly unusual way of declaring the font name. Why not just use “Helvetica Neue Light”? After a quick Google search I found that, as <span class="vcard">[Josh Pyles](http://pixelmatrixdesign.com/ "pixelmatrixdesign.com | Pixelmatrix Design")</span> and <span class="vcard">[Steve Cochrane](http://stevecochrane.com/v3/ "stevecochrane.com | Steve Cochrane")</span> [point](http://pixelmatrixdesign.com/blog/comments/advanced_web_typography/ "pixelmatrixdesign.com | Advanced Web Typography") [out](http://stevecochrane.com/v3/2007/12/13/helvetica-neue-variants-for-use-on-the-web/ "stevecochrane.com | Helvetica Neue variants for use on the web"), Safari allows you to use a font’s additional weights by referencing their PostScript<sup id="r2-080408">[2](#fn2-080408)</sup> names — in this case, “HelveticaNeue-Light” — in your <abbr>CSS</abbr>; whereas you simply declare the font’s full name (“Helvetica Neue Light”) in your stylesheets to use it in Firefox 2 and other Gecko-based browsers like Camino. Thus, the following declaration will give you gorgeous Helvetica Neue Light in almost every Mac browser:

<pre>font-family: "HelveticaNeue-Light", "Helvetica Neue Light",
             sans-serif;
</pre>

Almost every Mac browser, _except_ Firefox 3 and recent<sup id="r3-080408">[3](#fn3-080408)</sup> WebKit [nightly builds](http://nightly.webkit.org/ "webkit.org | WebKit Nightly Builds"), that is. Instead, you’ll get regular Helvetica Neue.

So what’s the deal? Why doesn’t this work in the nightlies anymore, when it worked in previous ones and in the shipping version<sup id="r4-080408">[4](#fn4-080408)</sup> of Safari? I thought it was a bug in nightly r31623, so I [filed it](http://bugs.webkit.org/show_bug.cgi?id=18311 "webkit.org | Bug 18311: REGRESSION (r31620): Font variants (e.g. Helvetica Neue *Light*) don't render correctly") and got a response from <span class="vcard">[Philippe Wittenbergh](http://l-c-n.com/phiw/ "l-c-n.com | Philippe Wittenbergh")</span>, stating:

> I believe the current (@ r31623) is correct. Per [<abbr>CSS</abbr> 2.1:15 Fonts](http://www.w3.org/TR/CSS21/fonts.html#font-family-prop "w3.org | 15.3 Font family: the 'font-family' property"), the author specifies a font ‘family’ (e.g. Helvetica Neue). If you then want a specific face (<abbr>e.g.</abbr> ‘Helvetica Neue-Ultra-Light’) within that family you use the `font-weight` property, in this case `font-weight: 100`.

Which is absolutely correct: Firefox 3 and the recent WebKit nightlies are simply following the standard to the letter, and calling a font face by its full or PostScript name is non-standard behavior<sup id="r5-080408">[5](#fn5-080408)</sup>. Shame on me for not knowing the <abbr>CSS</abbr> spec better. So, the standards-compliant way of getting Helvetica Neue Light is:

<pre>font-family: "Helvetica Neue", sans-serif;
font-weight: 300;
</pre>

For backwards compatibility, we can add both the PostScript and full names of the font to the declaration and end up with:

<pre>font-family: "HelveticaNeue-Light", "Helvetica Neue Light",
             "Helvetica Neue", sans-serif;
font-weight: 300;
</pre>

To sum up, if you want to use a specific font face, you have to use `font-family` along with the `font-weight` property, calling both the PostScript and screen names of that face for backwards compatibility. Now go forth and spruce up your websites with some beautiful typography.

1.  Unless you’re in Windows. Then you just get Arial. _I’m sorry_. [↑](#r1-080408)
2.  To find out the PostScript name of a font select it in Font Book and click Preview → Show Font Info (<kbd>⌘I</kbd>). [↑](#r2-080408)
3.  As of April 4th, 2008 (r31623.) [↑](#r3-080408)
4.  Safari 3.1, as of this writing. [↑](#r4-080408)
5.  Although a [patch](http://bugs.webkit.org/show_bug.cgi?id=18311#c9 "bugs.webkit.org | Comment #9 From mitz@webkit.org 2008-04-07 13:04 PDT [reply]") was submitted for the bug I filed, which reverts <q>old behavior for full-name based matches but prefer match by family name.</q> [↑](#r5-080408)
