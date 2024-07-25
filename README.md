# redmine_proxyauth

Log in users via HTTP headers set by oauth2-proxy.

This can be used if you are securing Redmine with an instance of [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/).

You have to configure your proxy setup to forward the header "X-Auth-Request-Access-Token". Then the user with that email will be logged in automatically. If the header is missing, you will be redirected to an error page.

