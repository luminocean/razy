require 'thread'
require_relative 'common'
require_relative 'lib'

module Razy
  @@pool = []
  @@mutex = Mutex.new
  @@main_thread_activation = ConditionVariable.new
  @@task_distribution = ConditionVariable.new
  @@task_queue = []
  @@current_task_count = 0

  module_function

  def start(main)
    main.call

    while @@task_queue.length > 0 or @@current_task_count > 0
      @@mutex.synchronize do
        @@main_thread_activation.wait(@@mutex)
      end
    end
  end

  def setup_thread_pool(size = 10)
    size.times do
      thread = Thread.new do
        # worker thread loop
        while true
          task = nil
          @@mutex.synchronize do
            # threads all waiting on the condition variable
            @@task_distribution.wait(@@mutex)
            # get task from queue exclusively once signaled
            task = @@task_queue.delete_at(0)
            @@current_task_count += 1
          end

          # conduct task
          task.call

          # work done, activate main thread to see is there anything left
          @@mutex.synchronize do
            @@current_task_count -= 1
            @@main_thread_activation.signal
          end
        end
      end
      @@pool << thread
    end
  end

  # setup thread pool immediately
  Razy.setup_thread_pool
end