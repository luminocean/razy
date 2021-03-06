require 'logger'
require 'thread'

# global log util
Log = Logger.new(STDOUT)
Log.formatter = proc { |severity, datetime, progname, msg|
  "[#{severity}]#{datetime} - #{msg}\n"
}

# make it easier to debug
# otherwise exceptions thrown from non-main threads will be covered
Thread.abort_on_exception = true

trap 'SIGINT' do
  # quit on SIGINT silently
  exit(0)
end