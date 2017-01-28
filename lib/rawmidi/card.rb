require 'rawmidi/api'
require 'rawmidi/device'

module RawMIDI
  class Card
    attr_reader :id, :name

    class << self
      def all
        API.each_card_id.map { |id| new(id) }
      end

      alias_method :[], :new
    end

    def initialize(id)
      @id = id
      @name = API.card_get_name(id)
    end

    def devices
      API.each_device_id(@id).map { |id| Device.new(self, id) }
    end

    def longname
      API.card_get_longname(@id)
    end
  end
end
