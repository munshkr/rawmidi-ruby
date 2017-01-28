module RawMIDI
  module Device
    attr_reader :id, :card, :name

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

    def inspect
      "#<#{self.class.name}:#{"0x%014x" % object_id} #{handle_name} #{@name.inspect} #{open? ? 'open' : 'closed'}>"
    end

    def open
      fail 'already open' if @midi_p
      @midi_p = API::Device.open(handle_name, direction, :sync)
      true
    end

    def close
      return if closed?
      API::Device.close(@midi_p)
      @midi_p = nil
      true
    end

    def open?
      !!@midi_p
    end

    def closed?
      !open?
    end
  end
end
