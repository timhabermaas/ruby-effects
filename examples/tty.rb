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
    Eff.handle_relay(Eff::FEFree.public_method(:return),
                    {TTY::Put => ->(p, k) { puts p.string; k.call(nil) },
                     TTY::Get => ->(g, k) { line = gets.chomp; k.call(line)}}).call(eff)
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
      Eff::FEFree.return outputs
    end
  end
end

program = TTY.put("What's your name?").bind do
  TTY.get.bind do |name|
    TTY.put("What's your age?").bind do
      TTY.get.bind do |age|
        TTY.put("Hi #{name}, you are #{age} years old.")
      end
    end
  end
end

Eff.run(TTY.run_io(program))
p Eff.run(TTY.run_simulated(["peter", "12"], program))
