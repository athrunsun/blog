---
title: "(Reproduce) String、StringBuffer与StringBuilder之间区别"
date: 2016/09/30 13:47
categories: Java
tags:
- Java
- String
---
[Original Post](http://silencewt.github.io/2015/05/11/【转载】String、StringBuffer与StringBuilder之间区别/)

Reproduced from [here](http://www.cnblogs.com/A_ming/archive/2010/04/13/1711395.html)

这两天在看Java编程的书，看到`String`的时候将之前没有弄懂的都理清了一遍，本来想将`String`之间的区别记录下来的，在找资料的时候发现这位网友整理的很不错，值得借鉴。我就在这个上面添一点自己的理解了。原文地址在上面。

关于这三个类在字符串处理中的位置不言而喻，那么他们到底有什么优缺点，到底什么时候该用谁呢？下面我们从以下几点说明一下:

1.三者在执行速度方面的比较：`StringBuilder` > `StringBuffer` > `String`

2.`String` < (`StringBuffer`，`StringBuilder`)的原因
```
String：字符串常量
StringBuffer：字符串变量
StringBuilder：字符串变量
```

从上面的名字可以看到，`String`是“字符串常量”，也就是不可改变的对象。对于这句话的理解你可能会产生这样一个疑问，比如这段代码：
```java
String s = "abcd";
s = s + 1;
System.out.print(s);// result: abcd1
```

我们明明就是改变了`String`型的变量s的，为什么说是没有改变呢? 其实这是一种欺骗，JVM是这样解析这段代码的：首先创建对象s，赋予一个abcd，然后再创建一个新的对象s用来执行第二行代码，也就是说我们之前对象s并没有变化，所以我们说`String`类型是不可改变的对象了，由于这种机制，每当用`String`操作字符串时，实际上是在不断的创建新的对象，而原来的对象就会变为垃圾被ＧＣ回收掉，可想而知这样执行效率会有多底。`String`类中每一个看起来会修改`String`值的方法，实际上都是创建一个全新的`String`对象，已包含修改后的字符串，而最初的`String`对象则丝毫未动。

而`StringBuffer`与`StringBuilder`就不一样了，他们是字符串变量，是可改变的对象，每当我们用它们对字符串做操作时，实际上是在一个对象上操作的，这样就不会像String一样创建一些而外的对象进行操作了，当然速度就快了。`StringBuffer`和`String`有很多相似之处，但是其内部的实现却有很大的差别，`StringBuffer`其实是一个分装一个字符数组，同时提供了对这个字符数组的相关操作。`StringBuffer()`构造一个字符缓冲区，其初始容量为16个字符。

3.一个特殊的例子：
```java
String str = "This is only a" + "simple" + "test";
StringBuffer builder = new StringBuilder("This is only a").append("simple").append("test");
```

你会很惊讶的发现，生成str对象的速度简直太快了，而这个时候`StringBuffer`居然速度上根本一点都不占优势。其实这是JVM的一个把戏，实际上`String str = "This is only a" + " simple" + "test";`其实就是`String str = "This is only a simple test";`

所以不需要太多的时间了。但大家这里要注意的是，如果你的字符串是来自另外的`String`对象的话，速度就没那么快了，譬如：
```java
String str2 = "This is only a";
String str3 = "simple";
String str4 = "test";
String str1 = str2 +str3 + str4;
```

这时候JVM会规规矩矩的按照原来的方式去做。

4.`StringBuilder`与`StringBuffer`
```
StringBuilder：线程非安全的
StringBuffer：线程安全的
```

当我们在字符串缓冲区被多个线程使用时，JVM不能保证`StringBuilder`的操作是安全的，虽然他的速度最快，但是可以保证`StringBuffer`是可以正确操作的。当然大多数情况下就是我们是在单线程下进行的操作，所以大多数情况下是建议用`StringBuilder`而不用`StringBuffer`的，就是速度的原因。

对于三者使用的总结：
> 1.如果要操作少量的数据用 = String
> 
> 2.单线程操作字符串缓冲区下操作大量数据 = StringBuilder
> 
> 3.多线程操作字符串缓冲区下操作大量数据 = StringBuffer.

关于三者的速度，自己写了个测试代码：
```java
package com.wt.others;

public class StringCompare {
    public static void main(String[] args) {
        // TODO Auto-generated method stub
        String text = "";
        long beginTime = 0l;
        long endTime = 0l;
        StringBuffer buffer = new StringBuffer();
        StringBuilder builder = new StringBuilder();
        beginTime = System.currentTimeMillis();
        for(int i=0; i<20000; i++){
            buffer.append(String.valueOf(i));
        }
        endTime = System.currentTimeMillis();
        System.out.println("StringBuffer time is : "+ (endTime - beginTime));

        beginTime = System.currentTimeMillis();
        for(int i=0; i<20000; i++){
            builder.append(String.valueOf(i));
        }
        endTime = System.currentTimeMillis();
        System.out.println("StringBuilder time is : "+ (endTime - beginTime));

        beginTime = System.currentTimeMillis();
        for(int i=0; i<20000; i++){
            text = text + i;
        }
        endTime = System.currentTimeMillis();
        System.out.println("String time is : "+ (endTime - beginTime));
    }
}
```

运行结果可以直观的看出：
```
StringBuffer time is : 5
StringBuilder time is : 3
String time is : 1550
```

如果将20000改为100，结果为：
```
StringBuffer time is : 1
StringBuilder time is : 0
String time is : 1
```

还是可以直观看出在单线程使用时，`StringBuilder`速度很快。
