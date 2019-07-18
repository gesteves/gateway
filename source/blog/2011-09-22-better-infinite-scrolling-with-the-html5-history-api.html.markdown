---
title: "Better infinite scrolling with the HTML5 History API"
description: "A technique to improve infinite or endless scrolling using the HTML5 History API."
canonical_url: https://www.gesteves.com/blog/2011/09/22/better-infinite-scrolling-with-the-html5-history-api/
---

_Originally published by [Guillermo Esteves](https://www.gesteves.com) on September 22nd, 2011_

***

Now that [Piictu][piictu] [finally launched][tc] and is out of beta, I want to write a bit about one of my favorite things I worked on as the front-end web developer there, which is our implementation of an infinite scrolling page improved by the use of the <abbr>HTML5</abbr> History <abbr>API</abbr>, the problem it tried to solve, and the solution we arrived at.

[tc]: http://techcrunch.com/2011/09/22/piictu-launches-grabs-seed-funding-to-grow-its-game-ified-photo-sharing-app/

## What’s Piictu?

A bit of background first. In case you haven’t tried it (and you totally should,) [Piictu][piictu] is an iPhone social photo app that revolves around the concept of “photo streams”, or threads of photos by different users on the same subject. For example, you can take a photo of a sandwich, start a stream titled “eating a sandwich”, and watch as your friends and followers reply with their own photos of their own sandwiches, or whatever they’re having for lunch. [Check it out][appstore], there are some incredibly creative games and memes going on over there. It’s a lot of fun.

[piictu]: http://piictu.com
[appstore]: http://itunes.apple.com/us/app/piictu/id439888569?mt=8&ls=1

Since these streams could conceivably have hundreds of photos, and we wanted an uninterrupted photo-viewing experience, we immediately decided to implement each photo stream as an infinitely-scrolling page, instead of using regular pagination. However, this concept of streams of thematically-related photos defined one of the main requirements for the design: we never wanted to take a photo out of its context, which meant that when people shared them, we couldn’t have traditional permalinks with just the one photo. The challenge was to figure out the best way to allow a user to share any photo without taking it out of the context of its stream.

## The problem with infinite scroll

I’m not a big fan of many sites’ implementations of infinite/endless scroll, and given a choice, I turn it off. Most times it just drives me nuts. For example, in most sites that use it, if my Internet connection goes out or there’s a server error or my browser crashes, I’m forced to start back at the top, which I find infuriating if I’m really deep down the page. Another problem is that I usually can’t bookmark my position, so if I leave and come back later, I’ll have to start over. So, in addition to the photo-sharing-on-an-infinite-page problem, I also wanted to tackle these issues, for a better user experience.

## The old Ajax way

My first idea when tackling this problem was a traditional solution using Ajax and fragment identifiers, so we could start the stream of photos at an arbitrary point defined by storing the ID of the desired photo in a <abbr>URL</abbr> hash (e.g. `/stream/123/#/photo/456`.) Since anything after the hash (#) character, or [fragment identifier][hash], in a <abbr>URL</abbr> isn’t sent to the server, this would require passing the photo ID to the server using Ajax, and loading the correct photos in the sequence with JavaScript. To make sharing easier, I wanted the hash fragment to be updated with the ID of the photo currently in the viewport as the user scrolls up and down, so they could share it by simply copying and pasting the <abbr>URL</abbr>.

[hash]: http://en.wikipedia.org/wiki/Fragment_identifier

<aside><p>For further reading about why this approach is not a very good idea, I recommend Tim Bray’s <a href="http://www.tbray.org/ongoing/When/201x/2011/02/09/Hash-Blecch">Broken Links</a>, Jeremy Keith’s <a href="http://adactio.com/journal/4346/">Going Postel</a>, and Mike Davies’s <a href="http://isolani.co.uk/blog/javascript/BreakingTheWebWithHashBangs">Breaking the Web with Hashbangs</a>.</p></aside>

However, I had a few issues with this approach. The first obvious one was that it doesn’t degrade gracefully. If the visitor doesn’t have JavaScript enabled or an error prevents the JavaScript from loading, then the user will get a nice empty page -- probably not the best experience. It also prevents the page from being crawled, not just by Google, but also by Facebook. When sharing or liking a page, Facebook determines what title, description, and thumbnail to display in the News Feed by crawling the page and looking for [Open Graph][og] tags, falling back to things like the `<title>` tag, description meta tags, and other images on the page. On a traditional permalink page like [Instagram][ell]’s, it’s easy, just set the Open Graph tags with the metadata of the one photo in the page. But on a page with a multitude of Ajax-loaded photos, without the server knowing which photo is being requested (remember, the server never gets the hash fragment,) how do you set these tags? If Facebook can’t see that information for the photo being shared, it wouldn’t know what to display in the News Feed, undermining what we set out to accomplish in the first place, which was to make it easier for users to share the photos. As an up-and-coming startup looking to get traffic and exposure, this was a real deal-breaker, so I quickly scrapped this solution.

[ell]: http://instagr.am/p/C5f6F/
[og]: https://developers.facebook.com/docs/opengraph/

## A better solution using the <abbr>HTML5</abbr> History <abbr>API</abbr>

<aside><p>For more information about the <abbr>HTML5</abbr> History <abbr>API</abbr>, read <a href="http://www.whatwg.org/specs/web-apps/current-work/multipage/history.html">Session History and Navigation</a> in the <abbr>HTML5</abbr> spec, <a href="https://developer.mozilla.org/en/DOM/Manipulating_the_browser_history">Manipulating the Browser History</a> at Mozilla Developer Center, and <a href="http://diveintohtml5.org/history.html">Manipulating History for Fun &amp; Profit</a> in Mark Pilgrim’s <cite>Dive into <abbr>HTML5</abbr></cite>.</p></aside>

Instead, I decided to use the [<abbr>HTML5</abbr> History <abbr>API</abbr>][whatwg]. Instead of getting the ID of the photo currently in the viewport and using it to change the fragment identifier, I update the <abbr>URL</abbr> in the address bar by calling the `replaceState()` method. The basic idea is this:

[whatwg]: http://www.whatwg.org/specs/web-apps/current-work/multipage/history.html

1. Wait for the `scroll` event to fire. (Note that since the `scroll` event can fire *a lot*, for performance reasons it’s best to run any code attached to this event after a small delay, using a `setInterval`, as per [John Resig’s recommendation][ejohn].)
2. When the page has scrolled, get the ID of the top-most photo in the viewport. For this I used the [Viewport Selectors][vs] jQuery plugin, which adds a handy `:in-viewport` selector. I also embedded the ID of each photo as a `data-photo-id` attribute in their markup, to make it easy to get with JavaScript.
3. If the browser supports the History <abbr>API</abbr>, use `replaceState()` to add the photo ID to the base <abbr>URL</abbr> of the stream page, or remove it, if it’s the first photo in the stream (i.e. if we scroll back to the top.) The reason I chose to use `replaceState()` (which updates the current browser history entry) instead of `pushState()` (which adds a new history entry) was because I didn’t want to have to click “back” a bunch of times and go back through every photo just to get to the previous page.

An abridged version of the JavaScript code used in Piictu looks somewhat like this (I removed some functionality that wasn’t really necessary for the History <abbr>API</abbr> explanation from the code, such as the actual infinite scroll implementation. I hope it’s clear enough): 

<script src="https://gist.github.com/gesteves/1a3ab87ce6c6f18b5a2aa895b18d9eb1.js"></script>

You can see this in action by going to any stream on Piictu, such as this [Hipstamatic][hip] stream I started a few months ago \[_NB: Piictu has been defunct for many years now, so evidently all these links are busted, but you can see the same effect on [my photoblog][aet], which uses a similar implementation._\] As you scroll up and down, you’ll notice that the ID of the photo in the viewport is appended to the <abbr>URL</abbr> of the stream page, and when you return to the top, it’s restored to the original <abbr>URL</abbr> (the `base_url` variable in the source code, which is also saved in a `data-*` attribute in the markup for easy retrieval.)

[aet]: https://www.allencompassingtrip.com

![Screenshot of the URL rewriting in action in Safari](blog/2011-09-22-better-infinite-scrolling-with-the-html5-history-api/piictu-stream.jpg)


[hip]: http://piictu.com/streams/4df4fcc02d26880001000353

So what happens on the server when we request a stream? If we request a plain stream <abbr>URL</abbr>, such as `/streams/123`, the server returns the first few photos normally, starting with the first photo in the stream. If we request a <abbr>URL</abbr> that contains a photo ID, like `/streams/123/photo/345`, the server again returns a few photos, but this time starting at the photo with the specified ID, with an option to load the photos above it, or scroll down to load more photos below. No need to use JavaScript to figure out which photos to show, it’s all returned directly from the server. Also, the metadata of the photo being requested is also returned as Open Graph tags in the `<head>` of the page, so when you post `/streams/123/photo/345` on Facebook or Google+, they’ll show the correct thumbnail and caption for that photo. It solves our goal for the photos, which was to help users to easily share them: regardless of whether they use the sharing buttons next to each photo, or simply grab the <abbr>URL</abbr> from the address bar and paste it in an instant message or their favorite social network, *it’ll just work*.

It also alleviates some of my pet peeves with infinite scrolling. Since the <abbr>URL</abbr> updates automatically as you move up and down the page, you can easily bookmark your position, which is particularly handy on very long streams; and if for whatever reason you’re forced to reload the page or your browser crashes, you’ll start where you left off, avoiding the frustration of having to start over (assuming your browser reopens your tabs after a crash.)

Finally, it degrades somewhat gracefully, as it’ll show the appropriate photos even if JavaScript is disabled, since JavaScript isn’t necessary to figure out which photos to load. (I say “somewhat” because it doesn’t yet offer regular pagination as a fallback, but it’s on the to-do list.)

[ejohn]: http://ejohn.org/blog/learning-from-twitter/
[vs]: http://www.appelsiini.net/projects/viewport

## What about Internet Explorer?

As always, the biggest issue with using any modern technology is Internet Explorer, since in this case it doesn’t support the History <abbr>API</abbr> in versions 9 and below. I briefly worked on a workaround for <abbr>IE</abbr>, using the ol’ hash fragments as a fallback. In the end we simply decided not to support <abbr>IE</abbr>, mainly because between January and May, Internet Explorer accounted for only 2.42% of the visits to our signup and teaser page, so the added effort and maintenance it would require seemed counterproductive. In addition, our implementation degrade gracefully in <abbr>IE</abbr>. The <abbr>URL</abbr> may not change as the user scrolls, but everything else works properly and sharing photos is still possible, using the Twitter and Facebook buttons. In other words, it simply behaves as a traditional implementation of infinite scroll. Finally, it’s a temporary situation, as [Internet Explorer 10 *will* support the History <abbr>API</abbr>][ie10], and it shouldn’t require any further work. I tested it in the [Windows 8 Developer Preview][win8], which includes a preview version of Internet Explorer 10, and it worked perfectly.

[ie10]: http://msdn.microsoft.com/en-us/ie/hh272905#_HTML5History
[win8]: http://msdn.microsoft.com/en-us/windows/apps/br229516

## Conclusion

I really believe that using the <abbr>HTML5</abbr> History <abbr>API</abbr> to augment infinite scrolling offers a superior user experience by alleviating some of the annoyances caused by traditional approaches, such as the lack of bookmarking and sharing. I expect this technique will be used more once Internet Explorer supports the History <abbr>API</abbr>, but if you’re willing to live without <abbr>IE</abbr> support for a bit (or use one of the many [polyfills][poly] available,) it’s definitely worth giving it a try now.

[poly]: https://github.com/Modernizr/Modernizr/wiki/HTML5-Cross-Browser-Polyfills

Let me know what you think about this; I look forward to your comments and questions, even though I still haven’t gotten around to adding comments to this blog. In the meantime, feel free to [tweet @gesteves][tweet] or [send me an email][email].

[tweet]: https://twitter.com/intent/tweet?text=%40gesteves%20 
[email]: mailto:contact@gesteves.com
