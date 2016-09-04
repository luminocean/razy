require_relative '../razy'

razy = Razy.new

main = proc do
  razy.tcp_server({:port => 8082}) do |err, socket|
    fail "TCP listener failed: #{err}" if err

    socket.read do |err, content|
      fail "socket read error: #{err}" if err

      # echo
      socket.write(content)
    end
  end
end

razy.start(main)