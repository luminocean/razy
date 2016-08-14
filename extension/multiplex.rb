require 'ffi'

module Razy
  module Multiplex
    READ_BUFFER_SIZE = 1024

    @@mutex = Mutex.new

    extend FFI::Library
    ffi_lib File.join(File.dirname(__FILE__) + '/multiplex.so')
    attach_function(:multiplex_initialize, [], :void)
    attach_function(:multiplex_set, [:pointer,:pointer, :int], :void)
    attach_function(:multiplex_wait, [], :int)
    attach_function(:multiplex_ready_fd, [:int], :int)

    # initialize IO multiplex functionality immediately
    multiplex_initialize

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

    def update_multiplex
      # reset kqueue listening array in C space
      fds = []
      modes = []
      @@fd_mode_map.each do |fd, mode|
        fds.push(fd)
        modes.push(mode)
      end

      multiplex_set(to_ffi_int_array(fds), to_ffi_int_array(modes), fds.length)
      Log.debug 'Registered fds updated'
    end

    def start_loop_thread
      Log.debug '0'
      Thread.new do
        # a dead loop
        # once got a ready event, call its coresponding task back
        while true
          Log.debug 'multiplex waiting...'
          nev = multiplex_wait
          Log.debug 'multiplex waiting finished'
          (0...nev).each do |i|
            fd = multiplex_ready_fd(i)
            task = @@fd_task_map[fd]
            task.call

            # return # sudden death
          end
        end
      end
    end

    # convert a ruby array into a fii compatible C-array pointer
    def to_ffi_int_array(array)
      pointer = FFI::MemoryPointer.new :int, array.length
      pointer.put_array_of_int(0, array)
      pointer
    end
  end
end