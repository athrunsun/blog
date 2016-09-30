---
title: "(Reproduce) TestNG Configuration Failures, Policy, and alwaysRun"
date: 2016/09/24 14:00
categories: Testing
tags:
- Testing
- TestNG
---
[Original Post](https://community.perfectomobile.com/posts/1094590-testng-configuration-failures-policy-and-alwaysrun)

TestNG Listeners are fundamental in setting up and managing our integration with Selenium driver behind the scenes of a test. The issue we may run into from time to time is the driver initialization may fail and unless you suppress the exception this will cause a configuration failure in testNG.

Below I will attempt to explain some things you can do to overcome the configuration failure and help you better handle it in your framework.

# alwaysRun

When configuration failures occur testNG's default behavior is to then skip every **after** listener down the line. For instance if your exception occurred in `beforeClass` or `beforeMethod` then `afterMethod` and `afterClass` will be skipped. You can solve the issue of subsequent **after** listeners not being executed by adding the attribute `alwaysRun=true` to the annotation of the listeners. This could be useful if you are collecting reporting information during your execution and your rely on these listeners to set some data for your reporting.

Remember to create flags to verify if any additional cleanup should be performed in the event that the **before** listeners DID fail. For instance if the driver was never created calling driver quit could throw another exception in your `afterMethod` execution.

```java
@AfterMethod(alwaysRun = true)
    public void afterMethod(Method method) {
```

# Should you add `alwaysRun` to your **before** listeners?

If you are adding group names to your methods you probably should but that is entirely up to you. When adding `alwaysRun` to **before** listeners it tells the listener that it is ok to run even if it doesn't contain the group name for the test specified in your `testng.xml` suite.

```java
@BeforeMethod(alwaysRun = true)
    public void beforeMethod(Method method)
```

If you wish to have a different set of **before** listeners which perform different behaviors based on the group name then you shouldn't use `alwaysRun`.

# configFailurePolicy

The default behavior of the `configFailurePolicy` setting has changed, purposely or not, from the behavior of "continue" to the behavior of "skip" over time. What this controls is whether the test methods should attempt to be ran regardless of a configuration failure. When set to skip the methods are skipped, when set to continue the methods attempt to run anyways.

In general you likely want your tests to skip because there is no need to attempt to run them if the driver has failed to initialize, to do so would only lead to additional failures and waste additional execution time. To force the setting of skip add the `configfailurepolicy="skip"` to the the suite tag of your `testng.xml`.

However if you wish to have the execution continue on for some reason you can change this to `configfailurepolicy="continue"`.

As of this writing the most current version of testNG is 6.9.10 and its default configfailurepolicy (what happens when this attribute is omitted from your testng.xml) is set to skip.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE suite SYSTEM "http://testng.org/testng-1.0.dtd">
<suite name="Suite" parallel="tests" thread-count="10" verbose="10" configfailurepolicy="skip">
  <listeners>
    <listener class-name="org.uncommons.reportng.HTMLReporter"/>
    <listener class-name="org.uncommons.reportng.JUnitXMLReporter"/>
    <listener class-name="utilities.TestListener" />
  </listeners>
  <test name="Test Chrome implicitNotVisible">
  <parameter name="targetEnvironment" value="Chrome" />
    <parameter name="network" value="" />
    <parameter name="networkLatency" value="" />
    <classes>
      <class name="AmazonTesting.SleepTestSystem">
        <methods>
          <include name="implicitNotVisible" />
        </methods>
      </class>
    </classes>
  </test>
</suite>
```
