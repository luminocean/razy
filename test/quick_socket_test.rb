#! /usr/bin/env ruby

require 'minitest/spec'
require 'minitest/autorun'
require 'socket'
require_relative '../razy'

class SocketIO < Minitest::Test
  def setup
    @razy = Razy.new
  end

  def teardown
    @server_thread.kill
  end

  def test_quick_socket_io
    port = 8095
    test_text = 'HELLO WORLD!'

    # add a quick-end socket server
    @server_thread = Thread.new do
      main = proc do
        @razy.tcp_server({:port => port}) do |err, socket|
          # write back text and end this socket connection immediately
          socket.end(test_text)
        end
      end

      # launch main loop
      @razy.start(main)
    end

    wait_for_server_up(port)

    Socket.tcp("localhost", port) do |sock|
      text = sock.read
      assert_equal(test_text, text)
    end
  end

  private

  def wait_for_server_up(port)
    # wait to server to boot
    while true
      # see is there any process listening on the specified port
      # (this approach probably only works on macOS)
      status = `lsof -n -i:#{port} | grep LISTEN`
      # we now have a process listening on our server port
      if status.split(/\s+/)[1] =~ /\d+/
        break
      end

      sleep 1
    end
  end
end