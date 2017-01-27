module RawMIDI
  class Device
    attr_reader :id, :card

    class << self
      def all
        Card.all.map { |c| c.devices }.flatten
      end
    end

    def initialize(card, id)
      @id = id
      @card = card
    end
  end
end
