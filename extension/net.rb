require 'ffi'

module Razy
  module Net
    # client socket object for easier user usage
    class Socket
      def initialize(fd)
        @fd = fd
        @io = IO.new(fd, mode: 'r+')
      end

      def end(message, &callback)
        end_handler = proc do
          @io.write(message)
          @io.close
          # once closed a fd, remember to remove it from kqueue list
          Razy::Multiplex.unregister(@fd)

          callback.call(nil)
        end
        Razy::Multiplex.register(@fd, 2, end_handler)
      end
    end

    module_function

    def load_c_extension
      extend FFI::Library
      ffi_lib File.join(File.dirname(__FILE__) + '/net.so')

      attach_function(:create_tcp_server, [:int], :int)
      attach_function(:accept_client_socket, [:int], :int)
    end

    # load c functions asap
    load_c_extension

    def accept(server_socket_fd)
      client_sokect_fd = accept_client_socket(server_socket_fd)
      Log.info "client socket fd: #{client_sokect_fd}"

      socket = Net::Socket.new(client_sokect_fd)
      socket
    end
  end
end