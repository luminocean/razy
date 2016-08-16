#! /usr/bin/env ruby

TEST_TEXT = 'HELLO WORLD!'
PORT = 8081

# fork a new server process
server_pid = fork do
  require_relative '../razy'

  main = proc do
    Razy.tcp_server({:port => PORT}) do |err, socket|
      fail 'TCP listener failed!' if err
      socket.end(TEST_TEXT)
    end
  end

  # launch main loop
  Razy.start(main)
end

require 'minitest/spec'
require 'minitest/autorun'
require 'socket'

describe 'Test TCP socket' do
  it 'test socket#end' do
    # wait to server to boot
    while true
      # see is there any process listening on the specified port
      # (this approach probably only works on macOS)
      status = `lsof -n -i:#{PORT} | grep LISTEN`
      # we now have a process listening on our server port
      if status.split(/\s+/)[1] =~ /\d+/
        puts 'Server up!'
        break
      end

      sleep 1
    end

    100.times do
      Socket.tcp("localhost", PORT) do |sock|
        assert_equal(TEST_TEXT, sock.read)
      end
    end
  end

  after do
    # kill the child server process on exit
    # otherwise the child won't quit by itself since it has a tcp server running inside
    puts 'Killing server process...'
    Process.kill('SIGINT', server_pid)
  end
end