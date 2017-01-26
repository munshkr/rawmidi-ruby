require 'ffi'

module RawMIDI
  module API
    extend FFI::Library

    ffi_lib 'libasound'

    enum :rawmidi_stream, [:output, :input]
    #enum :rawmidi_type,   [:type_hw, :type_shm, :type_inet, :type_virtual]

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

    # int snd_card_next(card&)
    attach_function :snd_card_next, [:pointer], :int

    # const char* snd_strerror(int error_number)
    attach_function :snd_strerror, [:int], :string

    # int snd_ctl_open(snd_ctl_t** ctl, const char* name, int mode)
    attach_function :snd_ctl_open, [:pointer, :pointer, :int], :int

    # int snd_ctl_close(snd_ctl_t* ctl)
    attach_function :snd_ctl_close, [:pointer], :int

    # int snd_ctl_rawmidi_next_device(snd_ctl_t* control, &device)
    attach_function :snd_ctl_rawmidi_next_device, [:pointer, :pointer], :int
    attach_function :snd_ctl_rawmidi_info, [:pointer, :pointer], :int

    # int snd_rawmidi_open(snd_rawmidi_t** input, snd_rawmidi_t output,
    attach_function :snd_rawmidi_open, [:pointer, :pointer, :string, :int], :int
    # int snd_rawmidi_close(snd_rawmidi_t* rawmidi)
    attach_function :snd_rawmidi_close, [:pointer], :int
    # int snd_rawmidi_write(snd_rawmidi_t* output, char* data, int datasize)
    attach_function :snd_rawmidi_write, [:pointer, :ulong, :size_t], :ssize_t

    # void snd_rawmidi_info_set_device(snd_rawmidi_info_t *obj, unsigned int val)
    attach_function :snd_rawmidi_info_set_device, [:pointer, :uint], :void
    # void snd_rawmidi_info_set_stream(snd_rawmidi_info_t *obj, snd_rawmidi_stream_t val)
    attach_function :snd_rawmidi_info_set_stream, [:pointer, :rawmidi_stream], :void
    # unsigned int snd_rawmidi_info_get_subdevices_count(const snd_rawmidi_info_t *obj)
    attach_function :snd_rawmidi_info_get_subdevices_count, [:pointer], :uint
    # const char* snd_rawmidi_info_get_name(const snd_rawmidi_info_t *obj)
    attach_function :snd_rawmidi_info_get_name, [:pointer], :string


    Error = Class.new(StandardError)

    def self.print_midi_ports
      card_p = FFI::MemoryPointer.new(:int).write_int(-1)
      status = snd_card_next(card_p)
      raise Error, snd_strerror(status) if status < 0

      card = card_p.read_int
      raise Error, 'no sound cards found' if card < 0

      while card >= 0 do
        list_midi_devices_on_card(card)
        status = snd_card_next(card_p)
        raise Error, snd_strerror(status) if status < 0
        card = card_p.read_int
      end
    end

    def self.list_midi_devices_on_card(card)
      name = "hw:#{card}"
      ctl_pp = FFI::MemoryPointer.new(:pointer)

      status = snd_ctl_open(ctl_pp, name, 0)
      if status < 0
        raise Error, "cannot open control for card #{card}: #{snd_strerror(status)}"
      end

      ctl_p = ctl_pp.read_pointer

      device_p = FFI::MemoryPointer.new(:int).write_int(-1)
      loop do
        status = snd_ctl_rawmidi_next_device(ctl_p, device_p)
        if status < 0
          snd_ctl_close(ctl_p)
          raise Error, "cannot determine device number: #{snd_strerror(status)}"
        end

        device = device_p.read_int
        list_subdevice_info(ctl_p, card, device) if device >= 0

        break if device < 0
      end

      snd_ctl_close(ctl_p)
    end

    def self.list_subdevice_info(ctl_p, card, device)
      info_p = FFI::MemoryPointer.new(:char, SndRawMIDIInfo.size, true)

      snd_rawmidi_info_set_device(info_p, device)

      snd_rawmidi_info_set_stream(info_p, :input)
      snd_ctl_rawmidi_info(ctl_p, info_p)
      subs_in = snd_rawmidi_info_get_subdevices_count(info_p)

      snd_rawmidi_info_set_stream(info_p, :output)
      snd_ctl_rawmidi_info(ctl_p, info_p)
      subs_out = snd_rawmidi_info_get_subdevices_count(info_p)

      puts "subs_in: #{subs_in}"
      puts "subs_outn: #{subs_out}"

      name = snd_rawmidi_info_get_name(info_p)
      puts "name: #{name}"
    end
  end
end
