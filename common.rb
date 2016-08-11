require 'logger'

Log = Logger.new(STDOUT)
Log.formatter = proc { |severity, datetime, progname, msg|
  "[#{severity}]#{datetime} - #{msg}\n"
}