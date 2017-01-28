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

    def handle_name
      "#{@card.handle_name},#{@id},0"
    end

    def input?
      @input
    end

    def output?
      @output
    end

    def inspect
      io_s = [input? && 'in', output? && 'out'].compact.join('/')
      "#<#{self.class.name}:#{"0x%014x" % object_id} #{handle_name} #{io_s} #{@name.inspect}>"
    end
  end
end
