require 'thread'
require_relative 'common'
require_relative 'io'

##
# main logic of Razy
##

class Razy
  MAX_WAIT_TIME = 30

  attr_reader :multiplex
  attr_reader :network

  def initialize
    @pool = []
    @mutex = Mutex.new
    @main_thread_activation = ConditionVariable.new
    @task_distribution = ConditionVariable.new
    @task_queue = []
    @flying_task_count = 0

    @multiplex = Multiplex.new(self)
    @network = Network.new(self)
  end

  def start(main)
    # set up thread pool and multiplex loop immediately
    setup_thread_pool
    @multiplex.start_loop_thread

    # go through main procedure first
    # set up first layer tasks and callbacks
    main.call

    while true
      # as long as there's any task waiting in the queue
      # signal a worker thread to handle a task
      while @task_queue.length > 0
        @mutex.synchronize do
          # dispatch this task to a worker thread
          @task_distribution.signal
          # waiting the thread to wake up and take this task
          # once returns, @task_queue should be deducted by 1
          @main_thread_activation.wait(@mutex, MAX_WAIT_TIME)

          # at this time point, the task has just be dispatched
          # but probably hasn't be conducted yet
        end
      end

      # even though no task is in the queue
      # there still might be some task being working
      # make sure they are done before exit
      if @flying_task_count > 0 or @multiplex.working?
        # some tasks are still running or waiting on IO multiplexing
        # waiting for them to complete
        @mutex.synchronize do
          @main_thread_activation.wait(@mutex, MAX_WAIT_TIME)
        end
      else
        return # no waiting or running task, exit completely
      end
    end
  end

  def setup_thread_pool(size = 10)
    size.times do
      thread = Thread.new do
        # worker thread
        while true
          task = nil
          @mutex.synchronize do
            # thread waiting on the condition variable until signaled
            # that means this thread has a task to work on
            @task_distribution.wait(@mutex)

            # get task from queue exclusively once signaled
            task = @task_queue.delete_at(0)
            @flying_task_count += 1

            # signal the main thread once the task has been taken cared of
            wakeup_main_thread
          end

          task.call

          # once the task call returns, the task is completed
          @mutex.synchronize do
            @flying_task_count -= 1
            # signal main thread for the second time to tell it that the task is completed
            # in case the main thread is sleeping because all tasks are running
            wakeup_main_thread
          end
        end
      end

      @pool << thread
    end
  end

  def wakeup_main_thread
    @main_thread_activation.signal
  end
end