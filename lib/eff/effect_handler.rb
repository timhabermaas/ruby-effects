module Eff
  class EffectHandler
    def self.with_state
      self.new(with_state: true)
    end

    def initialize(with_state: false)
      @impure_handlers = {}
      @pure_handler = Freer.public_method(:return)
      @with_state = with_state
    end

    def on_impure(klass, &block)
      @impure_handlers[klass] = block
      self
    end

    def on_pure(&block)
      @pure_handler = block
      self
    end

    def run(effect, state=nil)
      if @with_state
        handle_relay_state(@pure_handler, @impure_handlers, effect, state)
      else
        handle_relay(@pure_handler, @impure_handlers, effect)
      end
    end

    private
    def handle_relay(ret, impure_hash, effect)
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

      _loop.call(ret, impure_hash, effect)
    end

    def handle_relay_state(ret, impure_hash, eff, state)
      _loop = lambda do |ret, impure_hash, eff, state|
        case eff
        when Impure
          if impure_hash.key?(eff.v.class)
            e, new_state = impure_hash.fetch(eff.v.class).call(eff.v, eff.k, state)
            _loop.call(ret, impure_hash, e, new_state)
          else
            k = eff.k.qcomp(lambda { |e| _loop.call(ret, impure_hash, e, state) })
            Impure.new(eff.v, FTCQueue.singleton(k))
          end
        when Pure
          ret.call(eff.value, state)
        end
      end

      _loop.call(ret, impure_hash, eff, state)
    end
  end
end
