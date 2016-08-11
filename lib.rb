require_relative 'common'

# This file contains all the standard IO functions
module Razy
  module_function

  def read(file_path, &callback)
    task = proc do
      file = File.read(file_path)
      sleep(3)
      callback.call(nil, file)
    end

    # add task to queue and signal a thread to work
    @@mutex.synchronize do
      @@task_queue.push(task)
      @@task_distribution.signal
    end
  end
end