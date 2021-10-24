---
title: "Making intrinsic ratio elements with a max height"
description: "A little CSS technique I wrote for making elements with a fixed ratio that can also be constrained to a maximum height."
date: 2016/08/10
author: Guillermo Esteves
---

Here's something that took me longer than I care to admit to figure out how to do. I have [a photoblog](https://www.allencompassingtrip.com/) where I post the photos I take; I like to display them at high resolution, but when they're in a portrait orientation ([like this one](https://www.allencompassingtrip.com/2015/1/10/1026/lincoln-sky)), you usually can't see the whole photo, so I limit them to the height of the viewport and give the visitor the option to "zoom in" by tapping on it. At the same time, I'd like to reserve the space for the photo so it doesn't push the rest of the content down when it loads. To do this, I think most people are familiar with Thierry Koblentz's [intrinsic ratio](http://alistapart.com/article/creating-intrinsic-ratios-for-video) technique, published in [A List Apart](http://alistapart.com/) way back in 2009: in short, you give the element a `padding-top` (or `padding-bottom`, if you need to support ancient versions of IE) that's the height to width ratio you want as a percentage, then absolutely position the element inside. A 2:3 portrait photo's height is 150% of its width (3/2 * 100%), so you give the container a `padding-top: 150%` and you get:

<p data-height="265" data-theme-id="0" data-slug-hash="AXYLLV" data-default-tab="result" data-user="gesteves" data-embed-version="2" class="codepen">See the Pen <a href="http://codepen.io/gesteves/pen/AXYLLV/">Intrinsic ratio element</a> by Guillermo Esteves (<a href="http://codepen.io/gesteves">@gesteves</a>) on <a href="http://codepen.io">CodePen</a>.</p>
<script async src="//assets.codepen.io/assets/embed/ei.js"></script>

Well, now the space for the photo is reserved before it loads, but you can't see the whole thing. This is the part that took me a while to figure out: I want to limit the height of the photo to the height of the viewport, but since the height of its container is set by the padding, doing something like `max-height: 100vh` won't work.

Taking a step back, the reason why the `padding-top` trick works in the first place is because its percentage value is interpreted as a percentage of the width of its containing element. Therefore, if I want to limit the intrinsic ratio element's height, I'd need to limit its container's width, based on the width to height ratio of the image, and have said width be dependent on the viewport's height. A 2:3 element's width is 66.67% of its height (2/3 * 100%), but since I want it to depend on the viewport height, then the width of the wrapper element should be `66.67vh` (with a `max-width: 100%` to keep the width in check). Now I get:

<p data-height="265" data-theme-id="0" data-slug-hash="rLorrG" data-default-tab="result" data-user="gesteves" data-embed-version="2" class="codepen">See the Pen <a href="http://codepen.io/gesteves/pen/rLorrG/">Intrinsic ratio element with max height</a> by Guillermo Esteves (<a href="http://codepen.io/gesteves">@gesteves</a>) on <a href="http://codepen.io">CodePen</a>.</p>
<script async src="//assets.codepen.io/assets/embed/ei.js"></script>

Voilà, the element has an intrinsic ratio, it's as tall as the viewport, and if I want the photo to embiggen I can use a little bit of JS to increase the width of the wrapper element, which in turn would make the intrinsic ratio element (and the photo inside) taller.
