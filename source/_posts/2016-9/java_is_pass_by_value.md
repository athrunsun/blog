---
title: "(Reproduce) Java is Pass-by-Value, Dammit!"
date: 2016/09/30 10:00
categories: Testing
tags:
- Testing
- TestNG
---
[Original Post](http://javadude.com/articles/passbyvalue.htm)

# Introduction

I finally decided to write up a little something about Java's parameter passing. I'm really tired of hearing folks (incorrectly) state "primitives are passed by value, objects are passed by reference".

I'm a compiler guy at heart. The terms "pass-by-value" semantics and "pass-by-reference" semantics have very precise definitions, and they're often horribly abused when folks talk about Java. I want to correct that... The following is how I'd describe these

## Pass-by-value
> The actual parameter (or argument expression) is fully evaluated and the resulting value is copied into a location being used to hold the formal parameter's value during method/function execution. That location is typically a chunk of memory on the runtime stack for the application (which is how Java handles it), but other languages could choose parameter storage differently.

## Pass-by-reference
> The formal parameter merely acts as an alias for the actual parameter. Anytime the method/function uses the formal parameter (for reading or writing), it is actually using the actual parameter.

Java is *__strictly__* pass-by-value, exactly as in C. Read the Java Language Specification (JLS). It's spelled out, and it's correct. In [here](http://java.sun.com/docs/books/jls/third_edition/html/classes.html#8.4.1):

> When the method or constructor is invoked [(�15.12)](http://java.sun.com/docs/books/jls/third_edition/html/expressions.html#20448), the *__values__* of the actual argument expressions initialize newly created parameter variables, each of the declared **__Type__**, before execution of the body of the method or constructor. The *__Identifier__* that appears in the *__DeclaratorId__* may be used as a simple name in the body of the method or constructor to refer to the formal parameter.

[In the above, *__values__* is my emphasis, not theirs]

In short: Java has *__pointers__* and is strictly pass-by-value. There's no funky rules. It's simple, clean, and clear. (Well, as clear as the evil C++-like syntax will allow ;)

*Note: See the [note at the end of this article](http://javadude.com/articles/passbyvalue.htm#A%20Note%20on%20Remote%20Method%20Invocation) for the semantics of remote method invocation (RMI). What is typically called "pass by reference" for remote objects is actually incredibly bad semantics.*

# The Litmus Test

There's a simple "litmus test" for whether a language supports pass-by-reference semantics:

Can you write a traditional swap(a,b) method/function in the language?

A traditional swap method or function takes two arguments and swaps them such that variables passed into the function are changed outside the function. Its basic structure looks like

*Figure 1: (Non-Java) Basic swap function structure*
```
swap(Type arg1, Type arg2) {
    Type temp = arg1;
    arg1 = arg2;
    arg2 = temp;
}
```

If you can write such a method/function in your language such that calling

*Figure 2: (Non-Java) Calling the swap function*
```
Type var1 = ...;
Type var2 = ...;
swap(var1,var2);
```

actually switches the values of the variables var1 and var2, the language supports pass-by-reference semantics.

For example, in Pascal, you can write

*Figure 3: (Pascal) Swap function*
```
procedure swap(var arg1, arg2: SomeType);

    var
        temp : SomeType;
    begin
        temp := arg1;
        arg1 := arg2;
        arg2 := temp;
    end;

...

{ in some other procedure/function/program }

var
    var1, var2 : SomeType;

begin
    var1 := ...; { value "A" }
    var2 := ...; { value "B" } 
    swap(var1, var2);
    { now var1 has value "B" and var2 has value "A" }
end;
```

or in C++ you could write

*Figure 4: (C++) Swap function*
```
void swap(SomeType& arg1, Sometype& arg2) {
    SomeType temp = arg1;
    arg1 = arg2;
    arg2 = temp;
}

...

SomeType var1 = ...; // value "A"
SomeType var2 = ...; // value "B"
swap(var1, var2); // swaps their values!
// now var1 has value "B" and var2 has value "A"
```

(Please let me know if my Pascal or C++ has lapsed and I've messed up the syntax...)

But you cannot do this in Java!

# Now the details...

The problem we're facing here is statements like

*In Java, Objects are passed by reference, and primitives are passed by value.*

This is half incorrect. Everyone can easily agree that primitives are passed by value; there's no such thing in Java as a pointer/reference to a primitive.

However, *__Objects are not passed by reference__*. A correct statement would be *__Object references are passed by value__*.

This may seem like splitting hairs, bit it is *far* from it. There is a world of difference in meaning. The following examples should help make the distinction.

In Java, take the case of

*Figure 5: (Java) Pass-by-value example*
```java
public void foo(Dog d) {
    d = new Dog("Fifi"); // creating the "Fifi" dog
}

Dog aDog = new Dog("Max"); // creating the "Max" dog
// at this point, aDog points to the "Max" dog
foo(aDog);
// aDog still points to the "Max" dog
```

the variable passed in (aDog) *__is not__* modified! After calling foo, aDog *__still__* points to the "Max" Dog!

Many people mistakenly think/state that something like

*Figure 6: (Java) Still pass-by-value...*
```java
public void foo(Dog d) { 
    d.setName("Fifi");
}
```

shows that Java does in fact pass objects by reference.

The mistake they make is in the definition of

*Figure 7: (Java) Defining a Dog pointer*
```java
Dog d;
```

itself. When you write that definition, you are defining a *__pointer__* to a Dog object, *__not__* a Dog object itself.

## On Pointers versus References...

The problem here is that the folks at Sun made a naming mistake.

In programming language design, a "pointer" is a variable that indirectly tracks the location of some piece of data. The value of a pointer is often the memory address of the data you're interested in. Some languages allow you to manipulate that address; others do not.

A "reference" is an alias to another variable. Any manipulation done to the reference variable directly changes the original variable.

Check out the second sentence of [http://java.sun.com/docs/books/jls/third_edition/html/typesValues.html#4.3.1](http://java.sun.com/docs/books/jls/third_edition/html/typesValues.html#4.3.1).

> "The reference values (often just references) are pointers to these objects, and a special null reference, which refers to no object"

They emphasize "pointers" in their description... Interesting...

When they originally were creating Java, they had "pointer" in mind (you can see some remnants of this in things like
NullPointerException).

Sun wanted to push Java as a secure language, and one of Java's advantages was that it does not allow pointer arithmetic as C++ does.

They went so far as to try a different name for the concept, formally calling them "references". A big mistake and it's caused even more confusion in the process.

There's a good explanation of reference variables at [http://www.cprogramming.com/tutorial/references.html](http://www.cprogramming.com/tutorial/references.html). (C++ specific, but it says the right thing about the concept of a reference variable.)

The word "reference" in programming language design originally comes from how you pass data to subroutines/functions/procedures/methods. A reference parameter is an alias to a variable passed as a parameter.

In the end, Sun made a naming mistake that's caused confusion. Java has pointers, and if you accept that, it makes the way Java behaves make much more sense.

## Calling Methods

Calling

*Figure 8: (Java) Passing a pointer by value*
```java
foo(d);
```

passes the *__value of d__* to foo; it does not pass the object that d points to!

The value of the pointer being passed is similar to a memory address. Under the covers it may be a tad different, but you can think of it in exactly the same way. The value uniquely identifies some object on the heap.

*__However__*, it makes no difference how pointers are *__implemented__* under the covers. You program with them *__exactly__* the same way in Java as you would in C or C++. The syntax is just slightly different (another poor choice in Java's design; they should have used the same -> syntax for de-referencing as C++).

In Java,

*Figure 9: (Java) A pointer*
```java
Dog d;
```

is *__exactly__* like C++'s

*Figure 10: (C++) A pointer*
```cpp
Dog *d;
```

And using

*Figure 11: (Java) Following a pointer and calling a method*
```java
d.setName("Fifi");
```

is exactly like C++'s

*Figure 12: (C++) Following a pointer and calling a method*
```cpp
d->setName("Fifi");
```

To sum up: Java *__has__* pointers, and the *__value__* of the *__pointer__* is passed in. There's no way to actually pass an object itself as a parameter. You can only pass a pointer to an object.

Keep in mind, when you call

*Figure 13: (Java) Even more still passing a pointer by value*
```java
foo(d);
```

you're not passing an object; you're passing a *__pointer__* to the object.

For a slightly different (but still correct) take on this issue, please see [this](http://www-106.ibm.com/developerworks/library/j-praxis/pr1.html). It's from Peter Haggar's excellent book, Practical Java.)

# A Note on Remote Method Invocation (RMI)

When passing parameters to remote methods, things get a bit more complex. First, we're (usually) dealing with passing data between two independent virtual machines, which might be on separate physical machines as well. Passing the value of a pointer wouldn't do any good, as the target virtual machine doesn't have access to the caller's heap.

You'll often hear "pass by value" and "pass by reference" used with respect to RMI. These terms have more of a "logical" meaning, and really aren't correct for the intended use.

Here's what is usually meant by these phrases with regard to RMI. Note that this is not proper usage of "pass by value" and "pass by reference" semantics:

**RMI Pass-by-value**

> The actual parameter is serialized and passed using a network protocol to the target remote object. Serialization essentially "squeezes" the data out of an object/primitive. On the receiving end, that data is used to build a "clone" of the original object or primitive. Note that this process can be rather expensive if the actual parameters point to large objects (or large graphs of objects).

**This isn't quite the right use of "pass-by-value"; I think it should really be called something like "pass-by-memento". (See "Design Patterns" by Gamma et al for a description of the Memento pattern).**
 
**RMI Pass-by-reference**

> The actual parameter, which *is itself a remote object*, is represented by a proxy. The proxy keeps track of where the actual parameter lives, and anytime the target method uses the formal parameter, *another remote method invocation occurs* to "call back" to the actual parameter. This can be useful if the actual parameter points to a large object (or graph of objects) and there are few call backs.

**This isn't quite the right use of "pass-by-reference" (again, you cannot change the actual parameter itself). I think it should be called something like "pass-by-proxy". (Again, see "Design Patterns" for descriptions of the Proxy pattern).**

# Follow up from stackoverflow.com

*I posted the following as some clarification when a discussion on this article arose on http://stackoverflow.com.*

The Java Spec says that everything in java is pass-by-value. There is no such thing as "pass-by-reference" in java.

The key to understanding this is that something like

*Figure 14: (Java) Not a Dog; a pointer to a Dog*
```java
Dog myDog;
```

is not a Dog; it's actually a pointer to a Dog.

What that means, is when you have

*Figure 15: (Java) Passing the Dog's location*
```java
Dog myDog = new Dog("Rover");
foo(myDog);
```

you're essentially passing the address of the created Dog object to the foo method. (I say essentially b/c java pointers aren't direct addresses, but it's easiest to think of them that way)

Suppose the Dog object resides at memory address 42. This means we pass 42 to the method.

If the Method were defined as

*Figure 16: (Java) Looking at the called method in detail*
```java
public void foo(Dog someDog) {
    someDog.setName("Max");     // AAA
    someDog = new Dog("Fifi");  // BBB
    someDog.setName("Rowlf");   // CCC
}
```

Let's look at what's happening.

the parameter someDog is set to the value 42

**at line "AAA"**

> someDog is followed to the Dog it points to (the Dog object at address 42) that Dog (the one at address 42) is asked to change his name to Max

**at line "BBB"**

> a new Dog is created. Let's say he's at address 74 we assign the parameter someDog to 74

**at line "CCC"**

> someDog is followed to the Dog it points to (the Dog object at address 74) that Dog (the one at address 74) is asked to change his name to Rowlf then, we return

Now let's think about what happens outside the method:

*__Did myDog change?__*

There's the key.

Keeping in mind that myDog is a pointer, and not an actual Dog, the answer is NO. myDog still has the value 42; it's still pointing to the original Dog.

It's perfectly valid to follow an address and change what's at the end of it; that does not change the variable, however.

Java works exactly like C. You can assign a pointer, pass the pointer to a method, follow the pointer in the method and change the data that was pointed to. However, you cannot change where that pointer points.

In C++, Ada, Pascal and other languages that support pass-by-reference, you can actually change the variable that was passed.

If Java had pass-by-reference semantics, the foo method we defined above would have changed where myDog was pointing when it assigned someDog on line BBB.

Think of reference parameters as being aliases for the variable passed in. When that alias is assigned, so is the variable that was passed in.
