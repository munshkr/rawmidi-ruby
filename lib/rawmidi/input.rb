require 'rawmidi/device'
require 'rawmidi/api'

module RawMIDI
  class Input
    include Device

    def self.all
      Card.all.flat_map(&:inputs)
    end

    def input?
      true
    end

    def output?
      false
    end

    def read
      fail NotImplementedError
    end

    private

    def direction
      :input
    end
  end
end
