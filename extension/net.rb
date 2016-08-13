require 'ffi'

module Razy
  module Net
    # client socket object for easier user usage
    class Socket
      def read

      end

      def write

      end

      def end

      end
    end

    module_function

    def load_c_extension
      extend FFI::Library
      ffi_lib File.join(File.dirname(__FILE__) + '/net.so')

      attach_function(:create_tcp_server, [:int], :int)
    end

    # load asap
    load_c_extension

    def accept(server_socket_fd)

    end
  end
end