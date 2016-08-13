#! /usr/bin/env ruby

require_relative 'razy'

main = proc do
  Razy.tcp_server({:port => 8080}) do |err, socket|
    if err
      Log.error 'TCP listener failed!'
    else
      socket.end('Hi! Nice to meet you!')
    end
  end
end

# launch main loop
Razy.start(main)