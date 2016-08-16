Razy - 一个Ruby的异步IO库

# 1. 为什么要写Razy?

在Ruby的世界中,最常用的异步库是EventMachine。但是EventMachine并不支持普通文件(regular files)的读写API。为了能够在所有文件的读写上支持异步(普通文件,socket,pipe...)才有了Razy

# 2. 如何实现的?

将请求分成两部分处理。对于普通文件请求,交付线程池处理。对于其他请求,使用IO多路复用(IO multiplexing)来实现。

IO多路复用使用的是kqueue，因此目前只支持OSX(macOS)系统。
**由于Ruby本身并不支持这样的函数,因此底层使用C实现,编译后使用ffi加载调用。**(相关文件可参考extension目录)

API参考了Node.js风格。未来可能会支持Promise等方式来改善callback hell的问题。

# 3. 目前进展

对于普通文件的线程池读写已经完成。
目前正在完善基于kqueue的socket读写。之后会逐步实现基于epoll的对应实现。

# 4. 使用示例

这里给出一个简单的echo server的实现:

```
require_relative './razy'

main = proc do
  Razy.tcp_server({:port => 8082}) do |err, socket|
    fail "TCP listener failed: #{err}" if err

    socket.read do |err, content|
      fail "socket read error: #{err}" if err

      socket.end(content)
    end
  end
end

Razy.start(main)
```

使用`telnet localhost 8082`连接,测试如下:

```
> telnet localhost 8082
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
hello!
hello!
Connection closed by foreign host.
```
