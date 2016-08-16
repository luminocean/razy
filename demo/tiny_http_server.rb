require_relative '../razy'

main = proc do
  Razy.tcp_server({:port => 8082}) do |err, socket|
    fail 'TCP listener failed!' if err
    socket.read do |err, content|
      Log.info "CONGRATULATIONS! Content: #{content}"
      socket.end('bye')
    end
  end
end

Razy.start(main)