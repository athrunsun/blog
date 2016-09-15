---
title: (Rep) Difference between system testing and end to end testing?
date: 2016/02/16 16:25
categories: Testing
---
[Original Post](http://stackoverflow.com/questions/19378183/difference-between-system-testing-and-end-to-end-testing)

For me there isn't really a huge difference between the two and in some establishments the terms could be used interchangeably. Everywhere is different. I would try and explain it like so:

**System testing:** You're testing the whole system i.e. all of it's components to ensure that each is functioning as intended. This is more from a functional side to **check against requirements**.

**End to end testing:** This is more about the actual flow through a system in a more realistic end user scenario. Can a user navigate the application as expected and does it work. **You're testing the workflow**.

For example if you were to test an e-commerce site the shop front, browsing for items, cart and checkout would all work fine in systems test. You may then find issues with the workflow of moving between these areas of functionality in an end to end test.

Reference:

* [System Testing](http://en.wikipedia.org/wiki/System_testing)
* [End To End Testing](http://www.techopedia.com/definition/7035/end-to-end-test)