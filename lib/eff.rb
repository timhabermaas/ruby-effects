require 'eff/freer_monad'

module Eff
  def self.send(effect)
    Impure.new(effect, -> (x) { Pure.new(x) })
  end

  def self.handle_relay(ret, impure_hash)
    lambda do |eff|
      self.loop(eff, ret, impure_hash)
    end
  end

  def self.loop(eff, ret, impure_hash)
    case eff
    when Impure
      self.loop(impure_hash.fetch(eff.v.class).call(eff.v, eff.k), ret, impure_hash)
    when Pure
      ret.call(eff.value)
    end
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
