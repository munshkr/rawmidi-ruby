require 'rawmidi/api'
require 'rawmidi/device'

module RawMIDI
  class Card
    attr_reader :id, :name

    class << self
      def all
        API::Card.each_id.map { |id| new(id) }
      end

      alias_method :[], :new
    end

    def initialize(id)
      @id = id
      @name = API::Card.get_name(id)
    end

    def devices
      API::Device.each(@id).map { |id, info| Device.new(self, id, **info) }
    end

    def longname
      API::Card.get_longname(@id)
    end
  end
end
