module RawMIDI
  class Device
    attr_reader :id, :card, :name

    class << self
      def all
        Card.all.flat_map(&:devices)
      end
    end

    def initialize(card, id, **info)
      @id = id
      @card = card
      @name = info[:name]
      @input = info[:input]
      @output = info[:output]
    end

    def input?
      @input
    end

    def output?
      @output
    end

    def inspect
      io_s = [input? && 'in', output? && 'out'].compact.join('/')
      "#<#{self.class.name}:#{"0x%014x" % object_id} hw:#{@card.id},#{@id} #{io_s} #{@name.inspect}>"
    end
  end
end
