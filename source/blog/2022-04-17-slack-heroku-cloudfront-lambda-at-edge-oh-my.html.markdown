---
title: Slack and Heroku and CloudFront and Lambda@Edge, oh my!
description: How I used CloudFront and Lambda@Edge functions to work around free Heroku dyno limitations
date: 2022-04-17
author: Guillermo Esteves
---

I've spent the past few weeks rewriting a few of my old Slack bots, mainly because I wrote most of them years ago as custom integrations and wanted to learn how to build [modern Slack apps](https://api.slack.com/) (and also because building bots is just fun). In case you're curious, the three apps I ended up building were:

* [Wordlebot](https://wordlebot.gesteves.com), which shows stats about Wordle games in that Slack channel everyone seems to have where people post their scores.
* [Trebekbot](https://www.trebekbot.com/), which sets up a perpetual game of Jeopardy! in you Slack channels.
* [Weatherbot](https://weatherbot.gesteves.com/), which posts weather forecasts in Slack.

### How Slack apps work

The basic flow of these Slack apps is largely the same:

1. Someone performs an action in Slack, like mentioning the app (for example, `@Trebekbot`) or posting a `/slash` command (like Weatherbot's `/weather` command).
2. Slack makes a POST request to an endpoint on the app server with a payload describing the event. In my apps' case, `/slack/events` for events like app mentions and `/slack/slash` for slash commands.
3. The app enqueues some background job to do whatever the user requested, then immediately acknowledges response of Slack's request with an HTTP 200 status. For events, the response body can be empty; for slash commands, you can return `{"response_type":"in_channel"}` in the body if you want the user's slash command to be visible in channel.
4. Later on, the background job does whatever it needs to do, including, say, posting a message in Slack with the results.

Importantly, Slack requires that 200 status to be returned *within 3 seconds*, or the event delivery is considered a failure. For slash commands, [this results](https://api.slack.com/interactivity/slash-commands#responding_basic_receipt) in a "timeout was reached" error being shown to the user; for other events, Slack [retries up to three times](https://api.slack.com/apis/connections/events-api#the-events-api__responding-to-events), backing off exponentially. Slack strongly encourages the use of queues to handle events for this reason.

### My problem

That is all fine, except that I've been hosting all these apps on Heroku free dynos, because it's easy to set up, and I'm lazy, and cheap. However, [free dynos shut down after about 30 minutes of inactivity](https://devcenter.heroku.com/articles/free-dyno-hours#dyno-sleeping) and wake up when they receive a new request, but unfortunately take a bit longer than 3 seconds to do so. That means that if someone uses one of these apps while the dynos are asleep, one of these things might happen:

* If they post a slash command, the request will time out, the user will see that "timeout was reached" error in Slack, but then the dyno will finish waking up, enqueue the job, and successfully post the response. Not the end of the world, but I'd rather not show an error message to users, especially if the command is successful in the end.
* If it's some other event, such as an app mention, the request will time out, and Slack will keep retrying until the dyno is awake, which might result in multiple background jobs enqueued, and multiple responses from the app in Slack. Again, not the end of the world, but kind of annoying. (If you've invoked `@Trebekbot` and it responded with two or three games at once, that's why.)

The solution is simple: just upgrade the dynos to paid ones so they never go to sleep, duh. But again, I'm cheap, and frankly none of these apps see enough use to justify having dynos running 24/7. What to do?

### Enter CloudFront and Lambda@Edge

Since I already had these apps behind CloudFront, I started wondering if I could somehow make *CloudFront*, not *Heroku*, return the 200 status Slack expected, so it didn't have to wait for the dyno to be up. Turns out, the answer is yes, with some tweaking of CloudFront's configuration and a short Lambda@Edge function.

First, I set up two origins in my CloudFront distribution, both pointing to Heroku, but one using the default origin response timeout of 30 seconds and the other using the minimum timeout of 1 second.

Then, I set up two behaviors in the distribution: The Slack endpoints (`/slack/*`) would use the origin with the short timeout, and everything else would use the default one. That way, if someone hits, say, the app's website while the dyno is asleep, it'll render after a few seconds, when it wakes up. But if Slack posts to the `/slack/*` endpoints while the dyno is asleep, CloudFront will [respond with a 504 status](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-values-specify.html#DownloadDistValuesOriginResponseTimeout) (gateway timeout) after just 1 second. For both behaviors, if the dyno is awake, it'll handle the request as normal.

Finally, in the `/slack/*` behavior, I set up a Lambda@Edge function with an [origin response trigger](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-at-the-edge.html), which checks if the response is a 504 status, and if so, replaces the response with a 200 status with the appropriate body. Here's the entire function:

```
exports.handler = (event, context, callback) => {
    let response = event.Records[0].cf.response;
    const request = event.Records[0].cf.request;
    
    if (response.status === '504') {
        // If the request is due to a slash command,
        // return this JSON response so the command
        // is visible in channel.
        if (request.uri === '/slack/slash') {
            response = {
                status: '200',
                headers: {
                    'content-type': [{
                        key: 'Content-Type',
                        value: 'application/json'
                    }]
                },
                body: JSON.stringify({ response_type: "in_channel" })
            };
        } else {
        // Otherwise, just return an empty body.
            response = {
                status: '200',
                body: ''
            };
        }
    }
    callback(null, response); 
};
```

What ends up happening is:

1. A user performs an action in Slack, such as posting a slash command or mentioning the app.
2. Slack makes a POST request to the corresponding `/slack/*` endpoint, which sits behind CloudFront.
3. CloudFront receives the request from Slack and makes the request to the origin, Heroku.
4. If the Heroku dyno is awake, it receives the request, enqueues the background jobs, and returns a 200 response before CloudFront's 1 second timeout is up. CloudFront returns the 200 to Slack, and Slack is happy.
6. If the Heroku dyno is asleep, it begins waking up. However, after 1 second, CloudFront gives up and returns a 504 status. Meanwhile, the dyno finishes waking up and enqueues the background jobs.
7. The Lambda function executes, and since the response status from the origin was 504, it replaces the response with a 200, and returns it to Slack (with the appropriate body depending on the endpoint hit). Slack is happy!
8. A few seconds later, the background job runs, does whatever the user requested, and posts the result in Slack.

And with that, CloudFront is in charge of acknowledging receipt of Slack events when the Heroku dyno is asleep, users of these Slack apps don't get any error messages or odd behavior in those cases, and more importantly, it's saving me $7/month per dyno (and each of these apps has two!).