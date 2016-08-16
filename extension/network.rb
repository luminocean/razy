require 'ffi'

###
# C wrapper for network functionality
###

module Razy
  module Network
    # client socket object for easier user usage
    class Socket
      def initialize(fd)
        @fd = fd
        @io = IO.new(fd, mode: 'r+')
      end

      def read(&callback)
        read_handler = proc do
          content = @io.read_nonblock(1024)
          callback.call(nil, content) if block_given?
        end
        Razy::Multiplex.register(@fd, 1, read_handler)
      end

      def end(message, &callback)
        end_handler = proc do
          @io.write(message)
          Razy::Network::close(@io)
          callback.call(nil) if block_given?
        end
        Razy::Multiplex.register(@fd, 2, end_handler)
      end
    end

    module_function

    # accept a client socket from given server socket fd
    # please make sure the server socket is ready for accepting
    # otherwise this method would be blocked unexpectedly
    def accept(server_socket_fd)
      client_sokect_fd = accept_client_socket(server_socket_fd)
      Log.info "client socket fd: #{client_sokect_fd}"

      Razy::Network::Socket.new(client_sokect_fd)
    end

    private_class_method

    # close an io object whose file descriptor was used to be handled by IO multiplexing
    def close(io)
      # once closed a fd, remember to remove it from kqueue list
      # otherwise IO multiplexing will will wait on it which will cause an error
      Razy::Multiplex.unregister(io.fileno)
      # close this io object (the file descriptor underneath it in fact)
      io.close
      # signal the main thread just in case
      if Razy::Multiplex.waiting_fds.length == 0
        Razy.wakeup
      end
    end

    def load_c_extension
      extend FFI::Library
      ffi_lib File.join(File.dirname(__FILE__) + '/network.so')

      attach_function(:create_tcp_server, [:int], :int)
      attach_function(:accept_client_socket, [:int], :int, :blocking => true)
    end
    load_c_extension # load c functions asap
  end
end