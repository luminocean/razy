require_relative '../razy'

main = proc do
  Razy.tcp_server({:port => 8082}) do |err, socket|
    fail "TCP listener failed: #{err}" if err

    socket.read do |err, content|
      fail "socket read error: #{err}" if err

      Log.info "content: #{content}"
      socket.end(content)
    end
  end
end

Razy.start(main)