Razy - An asynchronous Ruby IO library

# 1. Why Razy?

In the Ruby world, probably the most commonly used async library is EventMachine.
Unfortunately, EventMachine doesn't support reading and writing for regular files.
In order to support IO of all kinds of files (including regualr file, pipe, socket, etc.),
I tried to write Razy.

# 2. How's razy implemented?

Simple. Requests are separated into two categories:
- Requests for regular files are handed over to a thread pool, using simple blocking IO to handle read/write operations.
- Requests for other files, sockets for example, IO multiplexing is used to handle IO operations.

Since razy is being developed in OSX for now, kqueue is used to do IO multiplexing.
** Because Ruby don't have native API for kqueue, the underlying infrastructure is implemented in C and is called from Ruby side using ffi**

Ideas of the API design came from Node.js thus something cool like Promise may also be implemented in razy in the future.

# 3. Current Process

Basic IO for regular files (based on thread pool) and sockets (based on kqueue) have been implemented.

# 4. Simple demo

Here's a simple implementation of an echo server:

```
require_relative './razy'

main = proc do
  Razy.tcp_server({:port => 8082}) do |err, socket|
    fail "TCP listener failed: #{err}" if err

    socket.read do |err, content|
      fail "socket read error: #{err}" if err

      # echo
      socket.write(content)
    end
  end
end

Razy.start(main)
```

Use `telnet localhost 8082` to connect.
Here's the output:

```
> telnet localhost 8082
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
hello!
hello!
Have a nice day!
Have a nice day!
^]
telnet> ^C
```
