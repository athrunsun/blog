---
title: Java Spring - "classpath:" and "classpath:*" prefix
date: 2016/01/22 21:52
categories: Java
---
#### [StackOverflow: Spring classpath prefix difference](http://stackoverflow.com/questions/3294423/)

The `classpath*:conf/appContext.xml` simply means that all `appContext.xml` files under conf folders in all your jars on the classpath will be picked up and joined into one big application context.

In contrast, `classpath:conf/appContext.xml` will load only one such file... the first one found on your classpath.

One very important thing - if you use the `*` and Spring finds no matches, it will not complain. If you don't use the `*` and there are no matches, the context will not start up!

#### [What is the difference between “classpath:” and “classpath:/” in Spring XML?](http://stackoverflow.com/questions/13994840/)

I don't see any difference between these two. The biggest difference that you will see is that the relative path and the `*` on the classpath location

Here is an excerpt from [Spring Resources](http://static.springsource.org/spring/docs/3.0.x/spring-framework-reference/html/resources.html), look for section 4.7.2.2

**Classpath*:**

The `classpath*:` prefix can also be combined with a PathMatcher pattern in the rest of the location path, for example `classpath*:META-INF/*-beans.xml`. In this case, the resolution strategy is fairly simple: a `ClassLoader.getResources()` call is used on the last non-wildcard path segment to get all the matching resources in the class loader hierarchy, and then off each resource the same PathMatcher resoltion strategy described above is used for the wildcard subpath.

This means that a pattern like `classpath*:*.xml` will not retrieve files from the root of jar files but rather only from the root of **expanded directories**. This originates from a limitation in the JDK's `ClassLoader.getResources()` method which only returns file system locations for a passed-in empty string (indicating potential roots to search).