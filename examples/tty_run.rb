require_relative './tty'

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
p Eff.run(TTY.run_simulated(["Peter", "12"], program))
