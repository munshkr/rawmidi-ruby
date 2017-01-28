require 'rawmidi/device'
require 'rawmidi/api'

module RawMIDI
  class Output
    include Device

    def self.all
      Card.all.flat_map(&:outputs)
    end

    def input?
      false
    end

    def output?
      true
    end

    def write(buffer)
      fail 'device is closed' if closed?
      API::Device.write(@midi_p, buffer)
    end

    private

    def direction
      :output
    end
  end
end
