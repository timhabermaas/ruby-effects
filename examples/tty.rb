require 'eff'

module TTY
  def self.put(s)
    Eff.send Put.new(s)
  end

  def self.get
    Eff.send Get.new
  end

  Put = Struct.new(:string)

  class Get
  end

  def self.run_io(eff)
    Eff::EffectHandler.new
      .on_impure(TTY::Put) { |p, k|
        puts p.string; k.call(nil)
      }
      .on_impure(TTY::Get) { |g, k|
        line = STDIN.gets.chomp; k.call(line)
      }
      .run(eff)
  end

  def self.run_simulated(answers, eff, outputs=[])
    Eff::EffectHandler.with_state
      .on_impure(TTY::Get) do |p, k, s|
        raise "not enough answers provided" if s[:answers].empty?
        [k.call(s[:answers].first), s.merge(answers: s[:answers][1..-1])]
      end
      .on_impure(TTY::Put) do |g, k, s|
        [k.call(nil), s.merge(outputs: s[:outputs] + [g.string])]
      end
      .on_pure do |_, s|
        Eff::Freer.return s[:outputs]
      end
      .run(eff, {answers: answers, outputs: outputs})
  end
end
