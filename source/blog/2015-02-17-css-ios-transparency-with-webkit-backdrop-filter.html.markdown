---
title: "Building iOS-like transparency effects in CSS with backdrop-filter"
description: "Here's how you can use the new -webkit-backdrop-filter property, to build cool iOS-like transparency effects with CSS."
date: 2015/02/17
author: Guillermo Esteves
---

Today, thanks to a [Vine](https://vine.co/v/OxmjlxdxKxl) video [Jason](https://twitter.com/jasonsantamaria) shared in our front-end Slack channel, I learned about the `-webkit-backdrop-filter` property, which landed very recently in the [WebKit Nightlies](http://nightly.webkit.org/). Like the existing `-webkit-filter` property, it allows you to apply `effects` such as `blur`, `grayscale`, `hue-rotate`, and others, only instead of applying them to the element itself, they're applied to whatever is _behind_ the element. This lets you to do some very iOS-like transparency effects, like what I did to The Verge's nav dropdown while experimenting with this:

![Transparency effect on The Verge](blog/2015-02-17-css-ios-transparency-with-webkit-backdrop-filter/Screen_Shot_2015-02-17_at_12.14.01_PM.0.png)

In this example, I gave the dropdown background a semi-transparent color, and added a simple `-webkit-backdrop-filter: blur(10px);` to it. Instead of blurring the dropdown itself, it blurs whatever the dropdown covers when it's open, giving it a little more depth by letting the blurred, colorful hero images show through.

You can see the effect in action in the following [pen](http://codepen.io/gesteves/pen/PwRPZa?editors=110), although you'll need to download and install the [WebKit Nightly](http://nightly.webkit.org/) build to check it out.

<p data-height="432" data-theme-id="0" data-slug-hash="PwRPZa" data-default-tab="result" data-user="gesteves" class="codepen">See the Pen <a href="http://codepen.io/gesteves/pen/PwRPZa/">PwRPZa</a> by Guillermo Esteves (<a href="http://codepen.io/gesteves">@gesteves</a>) on <a href="http://codepen.io">CodePen</a>.</p>

<script async src="//assets.codepen.io/assets/embed/ei.js"></script>

Evidently, as this just landed very recently in the nightlies, it'll be a while before this has enough browser support to let us use it in production, but it's cool nonetheless.
