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
      Eff.handle_relay(@pure_handler, @impure_handlers).call(effect)
    end
  end
end
