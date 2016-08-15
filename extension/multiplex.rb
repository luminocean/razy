require 'ffi'

###
# C wrapper for IO multiplexing functionality
###

module Razy
  module Multiplex
    READ_BUFFER_SIZE = 1024

    @@mutex = Mutex.new

    module_function

    # fd to its callback task
    @@fd_task_map = {}
    # fd to its mode
    @@fd_mode_map = {}

    # register a file descriptor and its mode with related callback proc
    def register(fd, mode, task)
      @@fd_task_map[fd] = task
      @@fd_mode_map[fd] = mode

      update_multiplex
    end

    # remember to call this method once a fd is closed
    # otherwise waiting for a closed fd will cause an error
    def unregister(fd)
      @@fd_task_map.delete(fd)
      @@fd_mode_map.delete(fd)

      update_multiplex
    end

    def start_loop_thread
      Thread.new do
        # an infinite loop
        # once got a ready event, call its corresponding task back
        while true
          Log.debug 'multiplex waiting...'
          nev = multiplex_wait
          Log.debug 'multiplex waiting finished'

          (0...nev).each do |i|
            fd = multiplex_ready_fd(i)
            task = @@fd_task_map[fd]
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
      @@fd_mode_map.each do |fd, mode|
        fds.push(fd)
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
      @@fd_task_map.keys
    end

    def load_c_extension
      extend FFI::Library
      ffi_lib File.join(File.dirname(__FILE__) + '/multiplex.so')
      attach_function(:multiplex_initialize, [], :void)
      attach_function(:multiplex_set, [:pointer,:pointer, :int], :void)
      attach_function(:multiplex_wait, [], :int, :blocking => true)
      attach_function(:multiplex_ready_fd, [:int], :int)

      multiplex_initialize
    end
    load_c_extension
  end
end