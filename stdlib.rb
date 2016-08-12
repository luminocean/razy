require_relative 'common'

# This file contains all the standard IO functions
module Razy
  module_function

  def read(file_path, &callback)
    task = proc do
      begin
        content = File.read(file_path)
        callback.call(nil, content)
      rescue => ex
        callback(ex)
      end
    end

    dispatch(task)
  end

  def write(file_path, content, &callback)
    task = proc do
      begin
        file = File.open(file_path, 'w')
        file.write(content)
        callback.call(nil)
      rescue => ex
        callback(ex)
      end
    end

    dispatch(task)
  end

  # dispatch task to threads in thread pool
  def dispatch(task)
    @@mutex.synchronize do
      @@task_queue.push(task)
      @@task_distribution.signal
    end
  end
end