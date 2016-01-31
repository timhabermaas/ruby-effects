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
      _loop = lambda do |ret, impure_hash, eff|
        case eff
        when Impure
          if impure_hash.key?(eff.v.class)
            _loop.call(ret, impure_hash, impure_hash.fetch(eff.v.class).call(eff.v, eff.k))
          else
            k = eff.k.qcomp(lambda { |e| _loop.call(ret, impure_hash, e) })
            Impure.new(eff.v, FTCQueue.singleton(k))
          end
        when Pure
          ret.call(eff.value)
        end
      end
      lambda do |eff|
        _loop.call(ret, impure_hash, eff)
      end
    end
  end
end
