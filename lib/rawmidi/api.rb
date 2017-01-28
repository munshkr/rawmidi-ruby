require 'ffi'

module RawMIDI
  module LibC
    extend FFI::Library

    ffi_lib FFI::Library::LIBC

    # Needed for some functions that expects the user frees memory after use
    attach_function :free, [:pointer], :void
  end

  module API
    extend FFI::Library

    ffi_lib 'libasound'

    enum :snd_ctl_mode, [:default, :nonblock, :async, :readonly]
    enum :snd_rawmidi_stream, [:output, :input]

    MODE_FLAGS = {append: 0x1, nonblock: 0x2, sync: 0x4}

    # snd_ctl
    class SndCtl < FFI::Struct
      layout :dl_handle, :pointer,      # void*
             :name, :pointer,           # char*
             :type, :pointer,
             :ops, :pointer,            # const snd_ctl_ops_t*
             :private_data, :pointer,   # void*
             :nonblock, :ulong,
             :poll_fd, :ulong,
             :async_handlers, :ulong
    end

    # snd_rawmidi_info
    class SndRawMIDIInfo < FFI::Struct
      layout :device, :uint,            # RO/WR (control): device number
             :subdevice, :uint,         # RO/WR (control): subdevice number
             :stream, :int,             # WR: stream
             :card, :int,               # R: card number
             :flags, :uint,             # SNDRV_RAWMIDI_INFO_XXXX
             :id, [:uchar, 64],         # ID (user selectable)
             :name, [:uchar, 80],       # name of device
             :subname, [:uchar, 32],    # name of active or selected subdevice
             :subdevices_count, :uint,
             :subdevices_avail, :uint,
             :reserved, [:uchar, 64]    # reserved for future use
    end

    # const char* snd_strerror(int error_number)
    attach_function :snd_strerror, [:int], :string

    # int snd_card_next(card&)
    attach_function :snd_card_next, [:pointer], :int
    # int snd_card_get_name(int card, char **name)
    attach_function :snd_card_get_name, [:int, :pointer], :int
    # int snd_card_get_longname(int card, char **name)
    attach_function :snd_card_get_longname, [:int, :pointer], :int

    # int snd_ctl_open(snd_ctl_t** ctl, const char* name, int mode)
    attach_function :snd_ctl_open, [:pointer, :pointer, :snd_ctl_mode], :int
    # int snd_ctl_close(snd_ctl_t* ctl)
    attach_function :snd_ctl_close, [:pointer], :int
    # int snd_ctl_rawmidi_next_device(snd_ctl_t* control, &device)
    attach_function :snd_ctl_rawmidi_next_device, [:pointer, :pointer], :int
    attach_function :snd_ctl_rawmidi_info, [:pointer, :pointer], :int

    # int snd_rawmidi_open(snd_rawmidi_t** input, snd_rawmidi_t** output, const char* name, int mode)
    attach_function :snd_rawmidi_open, [:pointer, :pointer, :string, :uint], :int
    # int snd_rawmidi_close(snd_rawmidi_t* rawmidi)
    attach_function :snd_rawmidi_close, [:pointer], :int
    # int snd_rawmidi_write(snd_rawmidi_t* output, char* data, int datasize)
    attach_function :snd_rawmidi_write, [:pointer, :pointer, :size_t], :ssize_t
    # void snd_rawmidi_info_set_device(snd_rawmidi_info_t *obj, unsigned int val)
    attach_function :snd_rawmidi_info_set_device, [:pointer, :uint], :void
    # void snd_rawmidi_info_set_subdevice (snd_rawmidi_info_t *obj, unsigned int val)
    attach_function :snd_rawmidi_info_set_subdevice, [:pointer, :uint], :void
    # void snd_rawmidi_info_set_stream(snd_rawmidi_info_t *obj, snd_rawmidi_stream_t val)
    attach_function :snd_rawmidi_info_set_stream, [:pointer, :snd_rawmidi_stream], :void
    # unsigned int snd_rawmidi_info_get_subdevices_count(const snd_rawmidi_info_t *obj)
    attach_function :snd_rawmidi_info_get_subdevices_count, [:pointer], :uint
    # const char* snd_rawmidi_info_get_name(const snd_rawmidi_info_t *obj)
    attach_function :snd_rawmidi_info_get_name, [:pointer], :string


    module Card
      def self.each_id
        return enum_for(__method__) unless block_given?

        card_p = FFI::MemoryPointer.new(:int).write_int(-1)

        loop do
          status = API.snd_card_next(card_p)
          fail Error, API.snd_strerror(status) if status < 0
          id = card_p.read_int

          break if id < 0
          yield id
        end
      end

      def self.with_control(card)
        return enum_for(__method__, card) unless block_given?

        ctl_pp = FFI::MemoryPointer.new(:pointer)
        status = API.snd_ctl_open(ctl_pp, "hw:#{card}", :readonly)
        if status < 0
          fail Error, "cannot open control for card #{card}: #{API.snd_strerror(status)}"
        end

        ctl_p = ctl_pp.read_pointer
        res = yield(ctl_p)

        API.snd_ctl_close(ctl_p)

        res
      end

      def self.get_name(id)
        name_pp = FFI::MemoryPointer.new(:pointer)
        status = API.snd_card_get_name(id, name_pp)
        fail Error, API.snd_strerror(status) if status < 0

        name_p = name_pp.read_pointer
        name = name_p.read_string
        LibC.free(name_p)

        name
      end

      def self.get_longname(id)
        name_pp = FFI::MemoryPointer.new(:pointer)
        status = API.snd_card_get_longname(id, name_pp)
        fail Error, API.snd_strerror(status) if status < 0

        name_p = name_pp.read_pointer
        name = name_p.read_string
        LibC.free(name_p)

        name
      end
    end

    module Device
      def self.each(card)
        return enum_for(__method__, card) unless block_given?

        Card.with_control(card) do |ctl_p|
          device_p = FFI::MemoryPointer.new(:int).write_int(-1)

          loop do
            status = API.snd_ctl_rawmidi_next_device(ctl_p, device_p)
            if status < 0
              API.snd_ctl_close(ctl_p)
              fail Error, "cannot determine device number: #{API.snd_strerror(status)}"
            end

            device = device_p.read_int

            break if device < 0

            info = subdevice_info(ctl_p, device)
            yield device, info
          end
        end
      end

      def self.subdevice_info(ctl_p, device, subdevice=0)
        info_p = FFI::MemoryPointer.new(:char, SndRawMIDIInfo.size, true)

        API.snd_rawmidi_info_set_device(info_p, device)
        API.snd_rawmidi_info_set_subdevice(info_p, subdevice)

        API.snd_rawmidi_info_set_stream(info_p, :input)
        status = API.snd_ctl_rawmidi_info(ctl_p, info_p)
        is_input = status >= 0

        API.snd_rawmidi_info_set_stream(info_p, :output)
        status = API.snd_ctl_rawmidi_info(ctl_p, info_p)
        is_output = status >= 0

        name = API.snd_rawmidi_info_get_name(info_p)

        {name: name, input: is_input, output: is_output}
      end

      def self.open(handle_name, direction, mode)
        midi_pp = FFI::MemoryPointer.new(:pointer)
        mode_n = API::MODE_FLAGS[mode]

        status = case direction
        when :output
          API.snd_rawmidi_open(nil, midi_pp, handle_name, mode_n)
        when :input
          API.snd_rawmidi_open(midi_pp, nil, handle_name, mode_n)
        else
          fail Error, 'invalid direction'
        end

        if status < 0
          fail Error, "cannot open device: #{API.snd_strerror(status)}"
        end

        midi_pp.read_pointer
      end

      def self.write(midi_p, buffer)
        buf_p = FFI::MemoryPointer.new(:char, buffer.size)
        buf_p.write_array_of_char(buffer)
        API.snd_rawmidi_write(midi_p, buf_p, buffer.size)
      end

      def self.close(midi_p)
        status = API.snd_rawmidi_close(midi_p)
        if status < 0
          fail Error, "cannot close device: #{API.snd_strerror(status)}"
        end
        true
      end
    end
  end
end
