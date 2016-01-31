# Examples

* `examples/tty.rb` shows how to represent STDIN and STDOUT as effects. It also includes two different effect handlers: `TTY.run_io` maps to Ruby's `puts` and `gets` and `TTY.run_simulated` is pure by getting a list of inputs and returning a list of outputs. `run_simulated` could be used for testing.
* `examples/http.rb` is a more involved example which uses a GitHub DSL to represent queries. These queries are then translated to HTTP effects which are then translated to actual HTTP requests. The `Http.run_cached` effect handler is particularly noteworthy: Caching can be accomplished without changing the implementation of `report_for`.

## Run

     $ bundle
     $ bundle exec ruby <example.rb>
