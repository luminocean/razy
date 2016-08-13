require 'ffi'

module Razy
  module Multiplex
    READ_BUFFER_SIZE = 1024

    extend FFI::Library
    ffi_lib File.join(File.dirname(__FILE__) + '/multiplex.so')

    attach_function(:initialize, :multiplex_initialize, [], :void)
    attach_function(:add, :multiplex_add, [:int,:int ], :void)
    attach_function(:wait, :multiplex_wait, [], :int)
    attach_function(:fd, :multiplex_ready_fd, [:int], :int)

    # initialize IO multiplex functionalities immediately
    initialize
  end
end

# Multiplex.add(0, 1)
#
# while true
#   nev = Multiplex.wait
#   break if nev <= 0
#
#   (0...nev).each do |i|
#     fd = Multiplex.fd(i)
#     file = IO.new(fd)
#     content = file.read_nonblock(Multiplex::READ_BUFFER_SIZE)
#     puts "CONGRATULATIONS: #{content}"
#   end
# end