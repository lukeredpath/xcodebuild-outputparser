#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), *%w[.. lib xcode_output_parser])

BUILD_COMMAND = "xcodebuild -target 'Unit Tests' -sdk iphonesimulator2.2 2> /dev/null"

class TestResultLiveOutputDelegate
    attr_reader :current_result
    attr_accessor :parser
    attr_reader :failures
      
    def start_parsing!
      @tests_run = 0
      @failures = []
      @start_time = Time.now
      puts "Started"
    end
    
    def finish_parsing!
      total_time = Time.now - @start_time
      puts
      puts "Finished in #{total_time} seconds."
      puts
      @failures.each_with_index do |failure, idx|
        puts "  #{idx+1}) #{failure[:brief]}"
        puts "  #{failure[:detail]}"
      end
      puts
      puts "#{@tests_run} tests, #{@failures.length} failures"
    end
    
    def start_test_suite(line)
      suite_name = line.match(/'(.*)'/)[1]
      if suite_name !~ /TestCase/
        puts "Loaded suite #{suite_name}:"
      end
    end
    
    def finish_test_suite(line)
      # if @current_test_suite
      #   finished_at = Time.parse(line.match(/finished at (.*)/)[1])
      #   @current_test_suite.finish(finished_at)
      #   @current_test_suite = nil
      # else
      #   finished_at = Time.parse(line.match(/finished at (.*)/)[1])
      #   @current_result.main_test_suite.finish(finished_at)
      # end
    end
    
    def parse_test_case(line)
      test_name = line.match(/'.*\stest(.*)\]'/)[1]
      @tests_run += 1
      if line.match(/passed/)
        print '.'
      elsif line.match(/failed/)
        @failures << {:brief => line.strip, :detail => @parser.previous_line.strip}
        print 'F'
      end
      STDOUT.flush
    end
  end

delegate = TestResultLiveOutputDelegate.new
parser = XcodeOutputParser::TestResultParser.new(delegate)
parser.parse_output_from_command(BUILD_COMMAND)
exit 1 if delegate.failures.length > 0
