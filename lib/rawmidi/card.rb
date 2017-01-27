require 'rawmidi/api'
require 'rawmidi/device'

module RawMIDI
  class Card
    attr_reader :id, :name

    class << self
      def all
        API.card_ids.map { |id| self.new(id) }
      end

      alias_method :[], :new
    end

    def initialize(id)
      @id = id
      @name = API.card_get_name(id)
    end

    def devices
      API.device_ids(@id).map { |id| Device.new(self, id) }
    end

    def longname
      API.card_get_longname(@id)
    end
  end
end
