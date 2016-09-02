require_relative '../razy'

main = proc do
  Razy.tcp_server({:port => 8082}) do |err, socket|
    fail "TCP listener failed: #{err}" if err

    socket.read do |err, content|
      fail "socket read error: #{err}" if err

      Razy.read_file('./index.html') do |err, file|
        socket.end(file)
      end
    end
  end
end

Razy.start(main)