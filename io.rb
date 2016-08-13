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

    dispatch(task)
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

    dispatch(task)
  end

  # dispatch task to threads in thread pool
  def dispatch(task)
    # simply add task to queue
    @@mutex.synchronize do
      @@task_queue.push(task)
    end
  end

  ### Network IO ###

  def tcp_server(options, &socket_handler)
    server_fd = Razy::Net.create_tcp_server(options[:port])

    # ready to [read] the server_fd
    Razy::Multiplex.add(server_fd, 1)

    # wait for IO multiplexing
    nev = Multiplex.wait
    puts "nev: #{nev}"
    # client_socket = Razy::Net.accept(server_fd)
    # socket_handler.call(nil, client_socket)
  end
end