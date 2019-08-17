---
title: "CSS glow effects with box-shadow"
description: "A really nice touch to add to a form, or any other elements you might want to highlight. And it’s easy, too."
date: 2010/03/26
author: Guillermo Esteves
---

If you’ve visited Twitter’s login screen lately in Safari, you might have noticed that the inputs have this subtle glow when they’re in focus:

![](blog/2010-03-26-css-glow-effects-with-box-shadow/1.png)

I love the way it looks and I think it’s a really nice touch to add to a form, or any other elements you might want to highlight. And it’s easy, too. Here’s how you do it:

    input {
        outline:none;
        transition: all 0.25s ease-in-out;
        -webkit-transition: all 0.25s ease-in-out;
        -moz-transition: all 0.25s ease-in-out;
    }

What I’m doing here is using `outline:none;` to get rid of the default highlight that Safari shows when an input is in focus, and then I’m setting the `transition` property to tell the input to animate any change to its properties. Read the [CSS Transitions][csstransitions] draft to know more about the options you can use. Here, I set it to animate for 0.25 seconds, easing in & out of the animation. I’m also setting the same property with vendor prefixes for WebKit & Mozilla.

[csstransitions]: http://www.w3.org/TR/css3-transitions/

    input:focus {
        box-shadow: 0 0 5px rgba(0, 0, 255, 1);
        -webkit-box-shadow: 0 0 5px rgba(0, 0, 255, 1); 
        -moz-box-shadow: 0 0 5px rgba(0, 0, 255, 1); 
    }

Now, when the user focuses on the input, I’m telling it to display a 5-pixels-wide box shadow with no offsets. Since the “shadow” is actually bright blue, it ends up looking like a glow. I’m also using RGBA so I can play with the opacity and make it more subtle if I want to. And again, I’m setting the same property with vendor prefixes so it’ll work with WebKit & Firefox. Since I set the `transition` property earlier, when the user focuses on the input, the box shadow won’t appear at once, and instead will be nicely animated. (Of course, if you want to apply this effect to other elements, you should target other pseudo-classes, like `:hover`.)

To make it look a bit nicer, I’m going to give it some rounded corners and a thinner border that will be highlighted when the input has focus:

    input {
        outline:none;
        transition: all 0.25s ease-in-out;
        -webkit-transition: all 0.25s ease-in-out;
        -moz-transition: all 0.25s ease-in-out;
        border-radius:3px;
        -webkit-border-radius:3px;
        -moz-border-radius:3px;
        border:1px solid rgba(0,0,0, 0.2);
    }

    input:focus {
        box-shadow: 0 0 5px rgba(0, 0, 255, 1);
        -webkit-box-shadow: 0 0 5px rgba(0, 0, 255, 1); 
        -moz-box-shadow: 0 0 5px rgba(0, 0, 255, 1);
        border:1px solid rgba(0,0,255, 0.8); 
    }

Here's the result:

![](blog/2010-03-26-css-glow-effects-with-box-shadow/2.png)
