require 'ffi'

###
# C wrapper for native functions
###

class Razy
  class Network
    def initialize(razy)
      @razy = razy
    end

    # accept a client socket from given server socket fd
    # please make sure the server socket is ready for accepting
    # otherwise this method would be blocked unexpectedly
    def accept(server_socket_fd)
      client_sokect_fd = Native.accept_client_socket(server_socket_fd)
      Socket.new(client_sokect_fd, @razy.multiplex)
    end

    def create_tcp_server(port)
      Native.create_tcp_server(port)
    end

    module Native
      extend FFI::Library
      ffi_lib File.join(File.dirname(__FILE__) + '/network.so')

      attach_function(:create_tcp_server, [:int], :int)
      attach_function(:accept_client_socket, [:int], :int, :blocking => true)
    end

    class Socket
      READ_SIZE = 1024

      def initialize(fd, multiplex)
        @fd = fd
        @io = IO.new(fd, mode: 'r+')
        @multiplex = multiplex
      end

      def read(&callback)
        read_handler = lambda do
          input = ''
          begin
            input = @io.read_nonblock(READ_SIZE)
          rescue IO::EAGAINWaitReadable
            # done reading for this batch
          rescue EOFError
            @multiplex.unregister(@fd, Multiplex::O_READ)
          rescue => ex
            callback.call(ex, nil) if block_given?
            @multiplex.unregister(@fd, Multiplex::O_READ)
          end

          # nothing left to read, return
          return if input.length == 0

          callback.call(nil, input) if block_given?
        end

        @multiplex.register(@fd, Multiplex::O_READ, read_handler)
      end

      def write(message, &callback)
        data_to_write = message.bytes
        total_len = message.length

        write_handler = lambda do
          begin
            len = @io.write_nonblock(data_to_write.pack('C*'))

            data_to_write = data_to_write.slice((len..-1))
            total_len -= len

            # nothing left to write
            if total_len == 0
              # unregister the write event after writing is done
              return @multiplex.unregister(@fd, Multiplex::O_WRITE)
            end

            @io.write(message)

            # flush immediately so that client
            # can receive this message asap
            @io.flush
            callback.call(nil) unless callback.nil?

            @multiplex.unregister(@fd, Multiplex::O_WRITE)
          rescue => ex
            callback.call(ex) unless callback.nil?
            @multiplex.unregister(@fd, Multiplex::O_WRITE)
          end
        end

        @multiplex.register(@fd, Multiplex::O_WRITE, write_handler)
      end

      def end(message, &callback)
        end_handler = lambda do
          begin
            @io.write(message)
            @io.close
            callback.call(nil) unless callback.nil?
          rescue => ex
            callback.call(ex) unless callback.nil?
          end

          # no need to unregister since closed fd is automatically unregistered
        end
        @multiplex.register(@fd, Multiplex::O_WRITE, end_handler)
      end
    end
  end
end