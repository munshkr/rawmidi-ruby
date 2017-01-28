require 'rawmidi/api'
require 'rawmidi/input'
require 'rawmidi/output'

module RawMIDI
  class Card
    attr_reader :id, :name

    def self.all
      API::Card.each_id.map { |id| new(id) }
    end

    def initialize(id)
      @id = id
      @name = API::Card.get_name(id)
    end

    def handle_name
      "hw:#{@id}"
    end

    def inputs
      API::Device.each(@id).select { |_, info| info[:input] }.map do |id, info|
        Input.new(self, id, name: info[:name])
      end
    end

    def outputs
      API::Device.each(@id).select { |_, info| info[:output] }.map do |id, info|
        Output.new(self, id, name: info[:name])
      end
    end

    def longname
      API::Card.get_longname(@id)
    end

    def inspect
      "#<#{self.class.name}:#{"0x%014x" % object_id} #{handle_name} #{@name.inspect}>"
    end
  end
end
