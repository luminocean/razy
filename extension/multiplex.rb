require 'ffi'
require 'json'
require_relative './kqueuer/kqueuer'

###
# C wrapper for IO multiplexing functionality
###

class Razy
  class Multiplex
    READ_BUFFER_SIZE = 1024

    O_READ = 1
    O_WRITE = 2

    def initialize(razy)
      @razy = razy
      @kq = KQueuer.new
      @loop = nil
    end

    def start_loop_thread
      return if @loop and @loop.alive?

      # one thread for IO multiplexing is enough
      @loop = Thread.new do
        while true
          events = @kq.wait
          # nothing returned, done
          if events.length == 0
            # tell main thread that event loop exits
            @razy.wakeup_main_thread
            break
          end

          events.each do |ev|
            if ev[:data].nil?
              puts ev
            end

            ev[:data][:callback].call
          end
        end
      end
    end

    # 1 for read and 2 for write
    def register(fd, mode, callback)
      start_loop_thread unless @loop.alive?
      @kq.register(fd, operation(mode), {
        :callback => callback
      })
    end

    def unregister(fd, mode)
      start_loop_thread unless @loop.alive?
      @kq.unregister(fd, operation(mode))
    end

    # whether this multiplex instance has any fd to wait on
    def working?
      @kq.instance_variable_get(:@memo).keys.length > 0
    end

    private_class_method

    def operation(mode)
      if mode == 1
        KQueuer::KQ_READ
      elsif mode == 2
        KQueuer::KQ_WRITE
      else
        STDERR.write "unknown mode, exit.\n"
        exit(1)
      end
    end
  end
end