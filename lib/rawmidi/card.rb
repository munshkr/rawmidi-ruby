require 'rawmidi/api'
require 'rawmidi/input'
require 'rawmidi/output'

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

    def handle_name
      "hw:#{@id}"
    end

    def devices
      API::Device.each(@id).flat_map do |id, info|
        devs = []
        devs << Input.new(self, id, name: info[:name]) if info[:input]
        devs << Output.new(self, id, name: info[:name]) if info[:output]
        devs
      end
    end

    def inputs
      devices.select(&:output?)
    end

    def outputs
      devices.select(&:output?)
    end

    def longname
      API::Card.get_longname(@id)
    end

    def inspect
      "#<#{self.class.name}:#{"0x%014x" % object_id} #{handle_name} #{@name.inspect}>"
    end
  end
end
