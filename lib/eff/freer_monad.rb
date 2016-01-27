module Eff
  class FEFree
    def self.return(x)
      Pure.new(x)
    end

    def >>(other)
      self.bind do |_|
        other
      end
    end
  end

  class Pure < FEFree
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def bind
      yield @value
    end
  end

  class Impure < FEFree
    attr_reader :v, :k

    def initialize(v, k)
      @v, @k = v, k
    end

    def bind(&block)
      Impure.new @v, -> (x) { @k.call(x).bind(&block) }
    end
  end
end
