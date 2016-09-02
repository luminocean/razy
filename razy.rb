require 'thread'
require_relative 'common'
require_relative 'io'

module Razy
  MAX_WAIT_TIME = 10

  @@pool = []
  @@mutex = Mutex.new
  @@main_thread_activation = ConditionVariable.new
  @@task_distribution = ConditionVariable.new

  # queue of tasks to be handled
  @@task_queue = []
  # how many task are being processed
  @@flying_task_count = 0

  module_function

  def start(main)
    # go through main procedure first
    # set up first layer tasks and callbacks
    main.call

    while true
      # as long as there's any task waiting in the queue
      # signal a worker thread to handle a task
      while @@task_queue.length > 0
        @@mutex.synchronize do
          @@task_distribution.signal
          # waiting the thread to wake up and take this task
          # once returns, @@task_queue should be deducted by 1
          @@main_thread_activation.wait(@@mutex, MAX_WAIT_TIME)
        end
      end

      if @@flying_task_count > 0 or Razy::Multiplex.waiting_fds.length > 0
        # some tasks are still running or waiting on IO multiplexing
        # waiting for them to complete
        @@mutex.synchronize do
          @@main_thread_activation.wait(@@mutex, MAX_WAIT_TIME)
        end
      else
        return # no running task, exit
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
            # thread waiting on the condition variable until signaled
            # that means this thread has a task to work on
            @@task_distribution.wait(@@mutex)

            # get task from queue exclusively once signaled
            task = @@task_queue.delete_at(0)
            @@flying_task_count += 1

            # signal the main thread once the task has been taken cared of
            wakeup
          end

          # conduct task separately
          task.call

          @@mutex.synchronize do
            @@flying_task_count -= 1
            # signal main thread for the second time to tell it that the task is completed
            # in case the main thread is sleeping because all task are being taking care of
            @@main_thread_activation.signal
          end
        end
      end

      @@pool << thread
    end
  end

  def setup_multiplex_loop
    Razy::Multiplex.start_loop_thread
  end

  def wakeup
    @@main_thread_activation.signal
  end

  # set up thread pool and multiplex loop immediately
  Razy.setup_thread_pool
  Razy.setup_multiplex_loop
end