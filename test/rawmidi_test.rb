require 'test_helper'

class RawMIDITest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::RawMIDI::VERSION
  end
end
