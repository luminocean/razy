require 'thread'
require 'logger'

Log = Logger.new(STDOUT)
Log.formatter = proc { |severity, datetime, progname, msg|
  "[#{severity}]#{datetime} - #{msg}\n"
}

class Razy
  @@mutex = Mutex.new
  @@alarm = ConditionVariable.new

  @@pool = []
  @@notify_data = {}

  def self.setup_thread_pool(size = 10)
    Log.info "Setting up #{size} theads in thread pool..."
    size.times do
      thread = RazyThread.new
      @@pool << thread
    end
  end

  def self.start(main)
    # setup all necessary logic
    Log.debug 'Calling main method'
    main.call

    # event loop begins
    while true
      @@mutex.synchronize do
        if @@notify_data.values.select{|nd| nd[:status] == :RUNNING}.length > 0
          Log.debug 'Main thread waiting...'
          @@alarm.wait(@@mutex)
          Log.debug 'Main thread wakeup'
        elsif @@notify_data.values.select{|nd| nd[:status] == :DONE}.length > 0
          id_to_delete = []
          @@notify_data.each do |id, nd|
            if nd[:status] == :DONE
              Log.debug 'Calling callback...'
              nd[:callback].call(nd[:data])
              id_to_delete << id
            end
          end
          id_to_delete.each{|id| @@notify_data.delete(id)}
        else
          Log.debug 'Bye'
          exit # no callback, exit
        end
      end
    end
  end

  def self.read(file_path, &callback)
    thread = @@pool[2].run do
      Log.debug 'Reading file...'
      file = File.read(file_path)
      sleep(3)
      Log.debug "Read file content: #{file}"

      nd = @@notify_data[@@pool[2].__id__]
      nd[:data] = file
      nd[:status] = :DONE

      @@mutex.synchronize do
        @@alarm.signal
      end
      Log.debug 'Signaled main thread'
    end

    @@notify_data[thread.__id__] = {
      :callback => callback,
      :data => nil,
      :status => :RUNNING
    }
  end
end

class RazyThread
  def initialize
    @mutex = Mutex.new
    @alarm = ConditionVariable.new
    @task = nil

    @thread = Thread.new do
      while true
        @mutex.synchronize do
          @alarm.wait(@mutex)
        end

        Log.info 'Calling thread task...'
        @task.call
        Log.info 'Thread task finished'
      end
    end
  end

  def run(&task)
    @task = task

    Log.info 'Waking up thread...'
    @mutex.synchronize{@alarm.signal}
  end

  def alive?
    @thread.alive?
  end
end

Razy.setup_thread_pool