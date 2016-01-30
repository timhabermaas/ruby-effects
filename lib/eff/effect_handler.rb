module Eff
  class EffectHandler
    def initialize
      @impure_handlers = {}
      @pure_handler = Freer.public_method(:return)
    end

    def on_impure(klass, &block)
      @impure_handlers[klass] = block
      self
    end

    def on_pure(&block)
      @pure_handler = block
      self
    end

    def run(effect)
      handle_relay(@pure_handler, @impure_handlers).call(effect)
    end

    private
    def handle_relay(ret, impure_hash)
      _loop = lambda do |eff, ret, impure_hash|
        case eff
        when Impure
          if impure_hash.key?(eff.v.class)
            _loop.call(impure_hash.fetch(eff.v.class).call(eff.v, eff.k), ret, impure_hash)
          else
            Eff::Impure.new(eff.v, -> (x) { _loop.call(eff.k.call(x), ret, impure_hash) })
          end
        when Pure
          ret.call(eff.value)
        end
      end
      lambda do |eff|
        _loop.call(eff, ret, impure_hash)
      end
    end
  end
end
