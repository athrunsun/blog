---
title: "(Reproduce) Lessons learned from a connection leak in production"
date: 2016-11-21 9:17
categories: Java
tags:
- Java
- HttpClient
---
[Original Post](http://phillbarber.blogspot.com/2014/02/lessons-learned-from-connection-leak-in.html)

We recently encountered a connection leak with one of our services in production.  Here's what happened, what we did and the lessons learned...

# Tests and Monitoring detected the issue (silently)
Our automated tests (which run in production for this service) started failing soon after the incident occurred.  We didn't immediately realise since they just went red on the dashboard and we just carried on about our business.  Our monitoring detected the issue immediately and also went red but crucially didn't email us due to an environment specific config issue.

## The alarm is raised
A tester on the team realises that the tests had been failing for some time (some time being 4 hours... eek!) and gets us to start investigating.

Myself and another dev quickly looked into what was going on with our poorly [dropwizard](http://dropwizard.codahale.com/) app.  We could see from the monitoring dashboard that the application's health check page was in error.  Viewing the page showed us that a downstream service (being called over http) was resulting in the following exception...

```
com.sun.jersey.api.client.ClientHandlerException:
org.apache.http.conn.ConnectionPoolTimeoutException: Timeout waiting for connection from pool
```

My gut reaction was that this was a timeout issue (since it usually is) and connections were not being released back to the connection pool after either slow connections or responses.  We saved the [metrics](http://dropwizard.codahale.com/manual/core/#metrics) info from the application and performed the classic `java kill -3` to get a thread dump for later reading.  We tried checking connectivity from the application's host to the downstream service with telnet which revealed no issue.  We also tried simulating a http request with `wget` which (after a bit of confusion trying to suppress ssl certificate checking) also revealed no issues.  With no more debug ideas immediately coming to mind, restoring service had to be the priority.  A restart was performed and everything went green again.

Looking in the code revealed no obvious problems.  We had set our timeouts like good boy scouts and just couldn't figure out what was wrong.  It clearly needed more investigation.

# We see the same thing happening in our Test environment... Great!
With a lot more time to debug (what seemed like) the exact same issue we came up with the idea of looking at the current connections on the box....

```
netstat -a
```

This revealed a lot of connections in the CLOSE_WAIT state.

A simple word count....

```
netstat -a  | grep CLOSE_WAIT | wc -l  
```

...gave us 1024 which just so happened to be the exact maximum size of our connection pool.  The connection pool was exhausted.  Restarting the application bought this down to zero and restored service as it did in production.

# Now we can monitor our leak
With the command above, we were able to establish how many connections in the pool were in the CLOSE_WAIT state.  The closer it gets to 1024, the closer we are to another outage.  We then had the great idea of piping this command into mailx and spamming the team with the number every few hours.

Until we fix the connection leak - we need to keep an eye on these emails and restart the application before the bucket over fills (i.e. the connection pool is exhausted).  

# What caused the leak?
We were using Jersey which in-turn was using HttpComponents4 to send a http request to another service.  The service being called was very simple and did not return any response body, just a status code which was all we were interested in.  If the status code was 200, the user was logged in, anything else we treat as unauthorised.

The code below shows our mistake....

```
public boolean isSessionActive(HttpServletRequest httpRequest) {
   ClientResponse response = jerseyClient
      .resource(url)
      .type(APPLICATION_JSON_TYPE)
      .header("Cookie", httpRequest.getHeader("Cookie"))
      .get(ClientResponse.class);
  return response.getStatus() == 200;
}
```

We were not calling `close()` on the `ClientResponse` object which meant that the response's input stream was not being closed, which meant that the connection was not released back into the pool.  This was a silly oversight on our part.  However, there's a twist...


We had run performance tests which in turn executed this method a million times (far more invocations than connections in the pool) without us ever hitting any issues.  The question was, if the code was wrong, why was it not failing all the time?  

# For every bug, there's a missing test
The task of creating a test which would fail reliably each time due to this issue was 99% of the effort in understanding what was going on.  Before we identified the above culprit, a tester on our team, amazingly, found the exact scenario which caused the leased connections to increase.  It seemed that each time the service responded with a 403, the number of leased connections would increase by one.

Our component tests mocked the service being called in the above code with a great tool called [wiremock](http://wiremock.org/) which allows you to fully mock a web service by sending http requests to a server under your control.  When we examined the number of leased connections after the mocked 403 response, frustratingly it did not increase.  There was something different from our mocked 403 response and the actual 403 response.

The issue was, in a deployed environment, we called the webservice through a http load balancer that was configured to give an html error page if the response was 4xx.  This scenario created an input stream on the `ClientResponse` object which needed to be closed.

As soon as we adjusted our wiremock config to return a response body, we observed the same connection leak as in our deployed environment.  Now we could write a test that would fail due to the bug.  Rather than stop there, we concluded that there was no point in us checking the status after the one test alone as next time it could fail in a different place.  We added the following methods and annotations to our test base class:

```
@Before
public void initialiseLeasedConnectionsCount() throws Exception{
   leasedConnectionCounts = getLeasedConnections();
}

@After
public void checkLeasedConnectionsHasNotIncremented() throws Exception{
   int leasedConnectionsAfter = getLeasedConnections();
   if (leasedConnectionCounts != leasedConnectionsAfter){
      fail("Expected to see leasedConnections stay the same but increased from : " + leasedConnectionCounts + " to: " + leasedConnectionsAfter);
   }
}
```

If we hit another connection leak, we'll know the exact scenario and it shouldn't get anywhere near production this time.  Now we have a failing test, lets make it pass by fixing the connection leak....

```
public boolean isSessionActive(HttpServletRequest httpRequest) {
   ClientResponse response = null;
   try{
      response = jerseyClient
         .resource(url)
         .type(APPLICATION_JSON_TYPE)
         .header("Cookie", httpRequest.getHeader("Cookie"))
         .get(ClientResponse.class);
      return response.getStatus() == SC_OK;
   }
   finally {
      if (response != null){
         response.close();
      }
   }
}
```

# Lessons Learned

## Make sure your alerts alert
Until you have proven you are actually getting emails to your inbox, all your wonderfully clever monitoring/alerting may be useless.  We lost 4 hours of availability this way!
I think that this is so important that I'm tempted to say it's worth causing an incident when everyone is paying attention just to prove you have all the bases covered. [Netflix do this as routine](http://techblog.netflix.com/2012/07/chaos-monkey-released-into-wild.html) and at random times too.

## A connection pool almost exhausted should fire an alert
If we had received an alert when the connection pool was at around 75% capacity, we would have investigated, our connection leak before it caused an outage.  This has also been mentioned by bitly [here](http://word.bitly.com/post/74839060954/ten-things-to-monitor).  I will endeavour to get this in place ASAP.


## Learn your tools
Getting a thread dump by sending your java process the SIGQUIT (i.e. kill -3 [java process id]) is fine but it relies on you having access to the box and permissions to run it.  In our case (using [dropwizard](http://dropwizard.codahale.com/) and [metrics](http://dropwizard.codahale.com/manual/core/#metrics)) all I needed to do was go to this url /metrics/threads on the admin port for exactly the same data formatted in json.

## Other Lessons?
If you can spot any other lessons learned from this, feel free to comment.

EDIT: [See here for a more detailed explanation of how to test for connection leaks and this time with all the code!](http://phillbarber.blogspot.co.uk/2015/02/how-to-test-for-connection-leaks.html)
