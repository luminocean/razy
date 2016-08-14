#! /usr/bin/env ruby

require_relative 'razy'

main = proc do
  Razy.tcp_server({:port => 8080}) do |err, socket|
    if err
      Log.error 'TCP listener failed!'
    else
      Log.info 'In socket handler!'

      socket.end("Perfect! Nice to meet you!\n") do |err|
        Log.info 'Message successfully sent!'
      end
    end
  end
end

# launch main loop
Razy.start(main)