require "eff/freer_monad"
require "eff/ftc_queue"
require "eff/effect_handler"

module Eff
  def self.send(effect)
    Impure.new(effect, FTCQueue.singleton(-> (x) { Pure.new(x) }))
  end

  def self.run(eff)
    case eff
    when Pure
      eff.value
    else
      raise "Effect #{eff.v} has not been handled. Are you missing an effect handler in your chain?"
    end
  end
end
