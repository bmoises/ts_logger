require 'logger'
require 'pry'

class Logger
  attr_accessor :logdev

  def add(severity, message = nil, progname = nil, &block)
    severity ||= UNKNOWN
    if @logdev.nil? or severity < @level
      return true
    end
    progname ||= @progname
    if message.nil?
      if block_given?
        message = yield
      else
        message = progname
        progname = @progname
      end
    end
    @logdev.write(
      format_message(format_severity(severity), Time.now, progname, message))
  end
     

  class LogDevice
    alias :old_write :write
    def write(message,writeout=false)
      # return message unless we write it out
      if writeout
        old_write(message)
      else
        message
      end
    end
  end
end

class TsLogger

  #extend Forwardable
    
  VERSION = "0.0.1"
  
  attr_accessor :device, :data, :mutex, :flush_mutex, :flush_variable

  #def_delegators :@device, :fatal, :error, :info, :debug

  # Takes same arguments as Logger
  def initialize logdev, shift_age = 0, shift_size = 1048576
    @device = Logger.new logdev, shift_age, shift_size
    @data = {}
    @ready_data = []
    @mutex = Mutex.new

    @flush_mutex = Mutex.new
    @flush_variable = ConditionVariable.new
  end

  def self.version_string
    "TsLogger version #{VERSION}"
  end

  def flush!
    lines = get_lines(Thread.current.object_id)
    @device.logdev.write( lines.join(), true )
  end

  def debug(progname = nil, &block)
    perform(:debug, progname)
  end

  def fatal(progname = nil, &block)
    perform(:fatal, progname)
  end

  def perform(method,progname = nil, &block)
    save_line(Thread.current.object_id, @device.send(method,progname) )
  end

  private
    def get_lines(thread_id)
      safely_perform do 
        @data.delete(thread_id)
      end
    end

    def save_line(thread_id, line)
      safely_perform do
        @data[thread_id] ||= []
        @data[thread_id] << line
      end
    end

    def safely_perform
      @mutex.synchronize {
        yield
      }
    end

end
