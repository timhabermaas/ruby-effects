require 'eff/freer_monad'

module Eff
  def self.send(effect)
    Impure.new(effect, -> (x) { Pure.new(x) })
  end

  def self.run(eff)
    case eff
    when Pure
      eff.value
    else
      # TODO list unhandled effects
      raise "not all effects have been handled"
    end
  end
end

require 'eff/effect_handler'
