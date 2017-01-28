module RawMIDI
  class Device
    attr_reader :id, :card, :name

    class << self
      def all
        Card.all.map { |c| c.devices }.flatten
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
  end
end
