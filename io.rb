require_relative 'common'
require_relative 'extension/multiplex'
require_relative 'extension/network'

##
# IO library of Razy
##

class Razy
  ###
  # File IO
  ###

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

  ###
  # Network IO
  ###

  def tcp_server(options, &handler)
    server_fd = @network.create_tcp_server(options[:port])
    # once a client try to connect this server process
    server_socket_handler = proc do
      # accept incoming client socket
      # this is supposed to be non-blocking
      client_socket = @network.accept(server_fd)
      handler.call(nil, client_socket)
    end

    # register the server fd in read mode
    @multiplex.register(server_fd, 1, server_socket_handler)
  end

  private

  # dispatch task to threads in thread pool to handle blocking IO
  def bio_dispatch(task)
    # simply add task to queue
    @mutex.synchronize do
      @task_queue.push(task)
    end
  end
end