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
    def ==(other)
      other.is_a?(Get)
    end
  end
end
