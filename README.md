
Jǫrmungandr
===========

Jǫrmungandr is a simple ORM, as in Object Redis Mapper. It enables very flexible
creation of Ruby objects backed by a Redis database. It is kind of similar
to Struct, but more dynamic. Model classes can be created like so:

    class Thing < Jormungandr::Model
    end

    thing = Thing.new

Thereafter, objects essentially are their own little key-value stores, wrapped
with some method_missing magic:

    thing.foo = "bar"
    thing.foo
      => "bar"

Similar magic is used for one-to-many mappings: If a method is called that is
a pluralization of the name of a Model subclass (e.g. Thing), it returns all
instances of that subclass that reference the object on which the method was
called.

    p = Person.new
    thing1.person = p
    thing2.person = p
    p.things
      => [thing1, thing2]


Features
--------

* When the Jormungandr class loads, the associated Redis database is scanned for
 hkeys beginning with "Jormungandr.". From each of these hashes, a corresponding
 Ruby object is created. 

* The Ruby object representing a model instance is very thin. It has one
 instance variable, @id, which corresponds to the Redis hashkey where the
 object is persisted.

* Attribute accessors are set up with method_missing magic, so there is no need
 to declare new attributes. It is up to the programmer to keep track of what
 attributes are used.

* The model objects will naively store attributes of any name. Every object is
 in effect its own little key-value store, with every key being a valid method
 of the object itself.

* In a Redis hash representing a model object, the values are Ruby objects
 serialized with Marshal.

* If the Sinatra module is loaded, a REST API is created through which the
 model objects can be accessed and manipulated using the standard HTTP verbs.
 Also, some admin views are created. (NOTE: Not yet merged into public repo!)

* If a method is called that is a pluralized form of a Model subclass, it
 returns all instances of this subclass that references the instance on wich
 the method was called (one-to-many relations).


Example of usage
----------------

    $ irb -r ./jormungandr
    > class Person < Jormungandr::Model; end
    => nil 
    > p = Person.new
    => #<Person:0x101115740 @id=0> 
    > p.name = "Martin"
    => "Martin" 
    > p.age = 28
    => 28 
    > exit
    $ irb -r ./jormungandr
    > Person.all
    => [#<Person:0x101125dc0 @id=0>] 
    > Person.all.first.name
    => "Martin" 
    > Person.all.first.age
    => 28 

Note that the Person class is created only once. In the second irb session,
Jǫrmungandr creates it when it finds a reference to it in the database.
