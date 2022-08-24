
# Points of Confusion:

**Downcasting**
---
From a new Chapel programmer perspective, I had some trouble figuring out how to cast from a child Class to Parent Class.

Specifically, this situation:
```chapel
class Parent { }
class Child: Parent { var some_field }

var c_p : shared Parent = new shared Child();

var c_c = c_p:(borrowed Child?)
```
produces an error message on the last line like: Cannot cast 'c_p' to a 'non-type'.

This is because the type of `some_field` is unconstrained which makes the cast illegal. However, that was not obvious from the error message. I think a better message would be something like: "cannot cast to Class "Child" because one or more of its fields is generic; please provide explicit type definitions."

Opened an issue about this here: https://github.com/chapel-lang/chapel/issues/20502

**Passing a shared SubClass to a shared SuperClass argument**
---

When passing a shared instance of a child class to a function that takes a shared instance of a parent class:
```chapel
proc foo(a: shared ParentClass) { }

const c = new shared ChildClass();
foo(c);
```
I get the following error message
```
expT.chpl:139: error: in call to 'foo', cannot pass result of coercion by reference
expT.chpl:139: note: implicit coercion from 'shared ChildClass' to 'shared ParentClass'
expT.chpl:39: note: when passing to 'const ref' intent formal 'head'
```

I found two ways to fix this.
1. change the function header to accept a `: borrowed ParentClass`. Not clear to me if this increases the reference count on the original c, or some temporary c' that is the result of the implicit coercion?
2. cast `c` to a `shared ParentClass` before passing to `foo`. This seems like the more correct solution; however, it would be nice if this happened automatically.

**Giving a method ownership of an owned Class instance**
---

Lets say I have a similar situation to above, except with an owned `c` and `borrowed` argument in foo:
```chapel
proc foo(a: borrowed ParentClass) { }

const c = new owned ChildClass();
foo(c); // foo uses c for a bit
writeln(c); // then I get it back here
```

What if I want to give foo ownership of `c`? (such that the last line of the above program would be an error)

I could not figure out a way to do this, but it seems like it could open the door for more control over how memory is being used. I.e. I can tell the compiler: "I am done with this thing when `foo` is done with it, please don't worry about giving it back". (Maybe the compiler already figures this type of thing out under the hood?)

# Feature Ideas

**Extracting Child Classes more Succinctly**
---

The pattern I used to cast from a Child to Parent class felt a bit indirect.

Here is a syntax modification that might make this type of conversion a bit more ergonomic (if something better doesn't exist already):

Instead of:
```chapel
var c = p:Child?;

if c != nil {
    writeln(c!.my_field);
}
```

What if we had the option to say:
```chapel
if var c! = p:Child? {
    writeln(c.my_field);
}
```

Rust has a similar pattern with the "if let" syntax. This is useful for doing things like destructuring the `Option<T>` enum which can be either `None` or `Some(T)` (where T is a generic value).

Example:
```rust
if let Some(value) = my_iterator.next() {
    writeln!(value);
}
```
