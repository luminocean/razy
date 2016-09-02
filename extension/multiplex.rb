require 'ffi'
require 'json'

###
# C wrapper for IO multiplexing functionality
###

module Razy
  module Multiplex
    READ_BUFFER_SIZE = 1024

    @@mutex = Mutex.new

    module_function

    @@fd_map = {}

    # register a file descriptor and its mode
    # with related callback proc
    def register(fd, mode, task)
      @@fd_map[fd] ||= {}
      @@fd_map[fd][mode] = task

      update_multiplex
    end

    # remember to call this method once a fd is closed
    # otherwise waiting for a closed fd will cause an error
    def unregister(fd, mode)
      @@fd_map[fd].delete(mode)
      @@fd_map.delete(fd) if @@fd_map[fd].keys.length == 0

      # unregister fd from kqueue immediately
      multiplex_unregister(fd, mode)
      # normal update
      update_multiplex
    end

    def start_loop_thread
      # one thread for IO multiplexing is enough
      Thread.new do
        # an infinite loop
        # once got a ready event, call its corresponding task back
        while true
          Log.debug 'multiplex waiting...'
          nev = multiplex_wait
          Log.debug 'multiplex waiting finished'

          (0...nev).each do |i|
            fd = multiplex_ready_fd(i)
            mode = multiplex_ready_fd_mode(i)

            # task = nil
            # @@fd_map[fd].each do |m, callback|
            #   if mode & 1 > 0
            #
            #     task = callback
            #     break
            #   end
            # end

            task = @@fd_map[fd][mode]
            if task.nil?
              puts "Error! mode is #{mode} | @@fd_map[fd] is: \n#{JSON.pretty_generate(@@fd_map[fd])}"
              next
            end
            task.call
          end
        end
      end
    end

    private_class_method

    # make the IO multiplexing wait for fds in @@fd_mode_map
    def update_multiplex
      fds = []
      modes = []
      @@fd_map.each do |fd, mode_map|
        fds.push(fd)

        mode = 0
        mode_map.keys.each do |m|
          mode |= m
        end

        modes.push(mode)
      end

      multiplex_set(to_ffi_int_array(fds), to_ffi_int_array(modes), fds.length)
      Log.debug 'Registered fds updated'
    end

    # convert a ruby array into a fii compatible C-array pointer
    def to_ffi_int_array(array)
      pointer = FFI::MemoryPointer.new :int, array.length
      pointer.put_array_of_int(0, array)
      pointer
    end

    # return fds the IO multiplexing is waiting for
    def waiting_fds
      @@fd_map.keys
    end

    def load_c_extension
      extend FFI::Library
      ffi_lib File.join(File.dirname(__FILE__) + '/multiplex.so')
      attach_function(:multiplex_initialize, [], :void)
      attach_function(:multiplex_set, [:pointer,:pointer, :int], :void)
      attach_function(:multiplex_wait, [], :int, :blocking => true)
      attach_function(:multiplex_unregister, [:int, :int], :void)
      attach_function(:multiplex_ready_fd, [:int], :int)
      attach_function(:multiplex_ready_fd_mode, [:int], :int)

      multiplex_initialize
    end
    load_c_extension
  end
end