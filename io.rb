require_relative 'common'
require_relative 'extension/multiplex'
require_relative 'extension/net'

# This file contains all the standard IO functions
module Razy
  module_function

  ### File IO ###

  def read_file(file_path, &callback)
    task = proc do
      begin
        content = File.read(file_path)

        callback.call(nil, content)
      rescue => ex
        callback(ex)
      end
    end

    bio_dispatch(task)
  end

  def write_file(file_path, content, &callback)
    task = proc do
      begin
        file = File.open(file_path, 'w')
        file.write(content)
        file.close

        callback.call(nil)
      rescue => ex
        callback(ex)
      end
    end

    bio_dispatch(task)
  end

  # dispatch task to threads in thread pool to handle blocking IO
  def bio_dispatch(task)
    # simply add task to queue
    @@mutex.synchronize do
      @@task_queue.push(task)
    end
  end

  ### Network IO ###

  def tcp_server(options, &handler)
    server_fd = Razy::Net.create_tcp_server(options[:port])
    server_socket_handler = proc do
      # accept incoming client socket without blocking
      client_socket = Razy::Net.accept(server_fd)
      handler.call(nil, client_socket)
    end

    # register task before add fd to IO multiplexing
    Razy::Multiplex.register(server_fd, 1, server_socket_handler)
  end
end