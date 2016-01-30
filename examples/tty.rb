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
    case eff
    when Eff::Impure
      if eff.v.class == Get
        raise "not enough answers provided" if answers.empty?
        run_simulated(answers[1..-1], eff.k.call(answers.first), outputs)
      elsif eff.v.class == Put
        run_simulated(answers, eff.k.call(nil), outputs + [eff.v.string])
      else
        Eff::Impure.new(eff.v, -> (x) { run_simulated(eff.k.call(x)) })
      end
    when Eff::Pure
      Eff::Freer.return outputs
    end
  end
end
