require 'spec_helper'

describe TsLogger do
  it 'should return TsLogger correct version string' do
    TsLogger.version_string.should == "TsLogger version #{TsLogger::VERSION}"
  end

  it 'should create a new logger device' do
    logger = TsLogger.new STDOUT
    logger.device.class.should == Logger
  end

  context 'method delegation' do
    it 'should delegate debug' do
      logger = TsLogger.new STDOUT
      logger.debug "Hello World"
      logger.debug "What in the world!?"
      logger.data[Thread.current.object_id].size.should == 2
    end

    it 'should delegate fatal' do
      logger = TsLogger.new STDOUT
      logger.fatal "Fatal Message"
      logger.data[Thread.current.object_id].size.should == 1
    end

  end

  it 'should not polinate from other threads' do 
  
    logger = TsLogger.new STDOUT
    logger.fatal "Fatal Message"
    logger.data[Thread.current.object_id].size.should == 1

    # inside a different thread, it should not collide
    Thread.new(logger) { |logger|
      logger.fatal "In a different thread"
      logger.data[Thread.current.object_id].size.should == 1
    }

    # In original thread
    logger.data[Thread.current.object_id].size.should == 1

    # Since we had another thread
    logger.data.size.should == 2
    
    # calling should should only print one
    logger.flush!
  end

  it 'should write out data as threads complete' do
    logger = TsLogger.new 'test.log'

    threads = []
    5.times do |t|

      Thread.new(logger, t) { |logger,t|
        num = rand(10) + 1
        num.times.each{ |i|
          logger.fatal "In thread[#{t}]: #{Thread.current.object_id}"
        }
        logger.data[Thread.current.object_id].size.should == num

        # Flush when we are done in this thread
        logger.flush!
      }
      
    end
    threads.each{|t| t.join }

    puts logger.data.inspect
    logger.data.size.should == 0
  end

end

