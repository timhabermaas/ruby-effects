# ruby_effects
[![Build Status](https://travis-ci.org/timhabermaas/ruby_effects.svg?branch=master)](https://travis-ci.org/timhabermaas/ruby_effects)

`ruby_effects` is a Ruby implementation of the [`freer` Haskell package](https://hackage.haskell.org/package/freer). The general idea is to represent effects as values and use interpreters to translate these effects into actual side-effects. See the paper [Freer Monads, More Extensible Effects](http://okmij.org/ftp/Haskell/extensible/more.pdf) for details.

## Disclaimer

I mainly developed this gem in order to get a deeper understanding of freer monads.
It is not (yet) meant to be used in production code.
This will hopefully change since I believe the underlying idea(s) are worth exploring outside of toy examples.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby_effects'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruby_effects


## Usage

Defining custom effects consists of three parts:

1. Coming up with types which represent the effects.
2. Wrapping the classes into the freer monad.
3. Writing custom effect handlers for these types.

### Custom effect class

Assume you want to create a DSL for a key-value store similar to Redis using `ruby_effects`.
In order to represent the operation [`GET`](http://redis.io/commands/get) you create a new Ruby class named `Get`:

```ruby
class Get
  attr_reader :key

  def initialize(key)
    @key = key
  end
end
```

That's just an ordinary Ruby class and the value `Get.new("foo")` represents asking
the store for the value of key `"foo"`.
This alone isn't very useful since there's currently no way to combine these values in
a meaningful way.
For example in order to get a value from the key-value store, count its length, write it back to the
store and return the length back to the caller, we'd like to write:

```ruby
def count_foos_length
  get("foo").bind do |value|
    set("foo_length", value.size).bind do |_|
      Eff::Pure.new(value) # Eff::Freer.return(value) would be equivalent
    end
  end
end
```

_Hint: Read `bind` as "and then" and this makes more sense._


### Freer monad

In order to get there we need to embed our types into the freer monad which provides
a way to compose different effects using `bind`.
The definition of `get` looks like this:

```ruby
def get(key)
  Eff::Impure.new(Get.new(key), -> (value) { Eff::Pure.new(value) })
end
```

This might look scary, but it's actually pretty intuitive. The freer monad consists
of two variants: `Pure` represents a pure value and the end of a computation.
`Impure` represents an ongoing computation. The first part of that computation is the effect _value_ (`Get.new(key)`)
and the second part is the continuation (aka what should happen next after `Get.new(key)` has been
executed).
So, reading it from left to right: Create a computation represented by `Get.new(key)` and
after handling that computation pass the result of that computation to `Eff::Pure.new` which
signals the end of the computation.


This boilerplate of embedding your custom types can be avoided by using `Eff.send` which expands
to the code above. The final defintions of `get` and `set` look like this:

```ruby
def get(key)
  Eff.send Get.new(key)
end

def set(key, value)
  Eff.send Put.new(key, value)
end
```

And that's it. Now you can combine `get` and `set` however you like using `bind`.
Speaking of `bind`: All it does is extending the continuation. If we apply the definition
of `bind` to `count_foos_length` we end up with something like this:

```ruby
def count_foos_length
  Eff::Impure.new(Get.new("foo"),
                  -> (v1) {
                    Eff::Impure.new(Put.new("foo_length", v1.size),
                                    -> (v2) {
                                      Eff::Pure.new(v1)
                                    })
                  })
end
```


### Effect handler

So far the (combined) effects are simple objects in memory. Calling `count_foos_length`
is completely side-effect free.

In order to define how an effect is to be interpreted we use `Eff::EffectHandler`
and its DSL. `on_impure` takes the class of the effect you want to handle and a
block which specifies what to do with that value:

```ruby
redis = Redis.new

def run_redis(effect)
  # Construct the effect handler using
  # chained on_impure calls for each
  # effect type.
  handler = Eff::EffectHandler.new
    # This `on_impure` block gets called if
    # the effect is of type `Get`. The passed in
    # parameters are the two parameters of `Impure`,
    # namely:
    # * `g` is the effect value, an object of class `Get`
    # * `cont` is the continuation
    .on_impure(Get) do |g, cont|
      value = redis.get(g.key)
      # Pass retrieved value to
      # the continuation
      cont.call(value)
    end
    .on_impure(Set) do |s, cont|
      redis.set(s.key, s.value)
      # Setting doesn't return anything,
      # so call continuation with nil.
      cont.call(nil)
    end

    # Actually run the handler on the effect.
    handler.run(effect)
end
```

Running an effect returns another freer monad with the specified effect types handled. In order
to escape the freer monad you need to call `Eff.run` at the end.

```ruby
Eff.run(run_redis(count_foos_length))
```

That's all there is to implement a DSL for a key-value store. You now have a way to describe arbitrary operations
on a key-value store and can interpret the programs in any way you like.
For the full implementation see `examples/redis.rb`. This example also contains a pure handler
which uses a simple hash map as the store instead of a running redis instance. That's pretty useful for
testing purposes. It would also be pretty easy to adding logging or in-memory caching without polluting
the implementation.


### Examples

For further inspiration take a look at the `examples/` folder.


## Motivation

Dependency Injection (DI) is a useful tool to accomplish separation of concerns and making code testable in the presence of side-effects.
Passing objects down the call stack is not fun and leads to accidental complexity, though.

When representing effects as values you avoid these drawbacks, make your code pure and still accomplish separation of concerns through effect handlers.
For example: You could add logging and caching to your effect handlers at the boundary while your core application remains unchanged.


## Caveats

*No do notation*: There's no do notation in Ruby to get rid of the nested `bind` calls which remind one of callback hell. There exists [`do_notation`](https://github.com/aanand/do_notation), but it is no longer maintained. Using [`method_source`](https://github.com/banister/method_source) in combination with [`ruby_parser`](https://github.com/seattlerb/ruby_parser) might be an alternative to get the same features. I'm currently working on it at [`ruby_monad`](https://github.com/timhabermaas/ruby_monad).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/timhabermaas/ruby_effects.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
