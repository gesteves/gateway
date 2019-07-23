This is a very simple personal homepage written in Middleman. In true [JAMstack][jam] fashion, it grabs some data from various APIs (mainly [my photoblog's][aet] GraphQL API, Github's GraphQL API, Goodreads's REST API, and Spotify's REST API, generates the site using Middleman (with the blogging extension used to handle some old blog posts), and deploys it to [Netlify][netlify]. A series of IFTTT webhooks periodically rebuilds the site whenever some of the data from the API changes (e.g. if I add a book to Goodreads, IFTTT checks my Goodreads profile RSS feed and fires off a webhook to Netlify to re-deploy the site).
 
[jam]: https://jamstack.org/
[aet]: https://www.allencompassingtrip.com/
[netlify]: https://www.netlify.com/
