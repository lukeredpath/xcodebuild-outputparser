require 'time'

module XcodeOutputParser
  class TestResultParser
    def parse_output(test_output)
      start_parsing!
      test_output.split("\n").each do |line|
        if line =~ /Test Suite(.*)started/
          if @current_result.main_test_suite
            start_test_suite(line)
          else
            start_main_test_suite(line)
          end
        end
        if line =~ /Test Suite(.*)finished/
          if @current_test_suite
            finish_test_suite(line)
          else
            finish_main_test_suite(line)
          end
        end
      end
      @current_result
    end
    
    private
    
    def start_parsing!
      @current_result = TestResult.new
      @current_test_suite = nil
    end
    
    def start_main_test_suite(line)
      suite_name = File.basename(line.match(/'(.*)'/)[1])
      started_at = Time.parse(line.match(/started at (.*)/)[1])
      @current_result.main_test_suite = TestResult::TestSuite.new(suite_name)
      @current_result.main_test_suite.start(started_at)
    end
    
    def finish_main_test_suite(line)
      finished_at = Time.parse(line.match(/finished at (.*)/)[1])
      @current_result.main_test_suite.finish(finished_at)
    end
    
    def start_test_suite(line)
      suite_name = line.match(/'(.*)'/)[1]
      started_at = Time.parse(line.match(/started at (.*)/)[1])
      @current_test_suite = TestResult::TestSuite.new(suite_name)
      @current_test_suite.start(started_at)
      @current_result.test_suites << @current_test_suite
    end
    
    def finish_test_suite(line)
      finished_at = Time.parse(line.match(/finished at (.*)/)[1])
      @current_test_suite.finish(finished_at)
      @current_test_suite = nil
    end
  end
  
  class TestResult
    attr_accessor :main_test_suite
    attr_reader :test_suites
    
    def initialize
      @test_suites = []
    end
    
    class TestSuite
      attr_reader :name
      attr_reader :started_at
      attr_reader :finished_at
      
      def initialize(name)
        @name = name
      end
      
      def start(start_time)
        @started_at = start_time
      end
      
      def finish(finish_time)
        @finished_at = finish_time
      end
    end
  end
end