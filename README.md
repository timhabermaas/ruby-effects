# ruby_effects
[![Build Status](https://travis-ci.org/timhabermaas/ruby_effects.svg?branch=master)](https://travis-ci.org/timhabermaas/ruby_effects)

Ruby-Effects is a Ruby implementation of the [`freer` Haskell package](https://hackage.haskell.org/package/freer). The general idea is to represent effects as values and use interpreters to translate these effects into actual side-effects. See the paper [Freer Monads, More Extensible Effects](http://okmij.org/ftp/Haskell/extensible/more.pdf) for details.

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

TODO Explain how to create custom effects and custom handlers.

### Examples

To get a feel for how code using `ruby_effects` might look like, take a look at the `examples/` directory.

* `examples/tty.rb` shows how to represent STDIN and STDOUT as effects. It also includes two different effect handlers: `TTY.run_io` maps to Ruby's `puts` and `gets` and `TTY.run_simulated` is pure by getting a list of inputs and returning a list of outputs. `run_simulated` could be used for testing.
* `examples/http.rb` is a more involved example which uses a GitHub DSL to represent queries. These queries are then translated to HTTP effects which are then translated to actual HTTP requests. The `Http.run_cached` effect handler is particularly noteworthy: Caching can be accomplished without changing the implementation of `report_for`.

The examples can be run using `cd examples; bundle exec ruby <example>.rb`.


## Motivation

Dependency Injection (DI) is a useful tool to accomplish separation of concerns and making code testable in the presence of side-effects.
Passing objects down the call stack is not fun and leads to accidental complexity, though.

When representing effects as values you avoid these drawbacks, make your code pure and still accomplish separation of concerns through effect handlers.
For example: You could add logging and caching to your effect handlers without polluting your application with log statements.


## Caveats

*No do notation*: Since there's no do notation in Ruby the nested `bind` calls remind one of callback hell. There exists [`do_notation`](https://github.com/aanand/do_notation), but it is no longer maintained. Using [`method_source`](https://github.com/banister/method_source) in combination with [`ruby_parser`](https://github.com/seattlerb/ruby_parser) might be an alternative to get the same features.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/timhabermaas/ruby_effects.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
