require 'time'

module Xcode
  module BuildParser
    class ReporterDelegate
      attr_reader :current_result
      attr_accessor :parser

      def start_parsing!
        @current_result = TestResult.new
        @current_test_suite = nil
      end
  
      def finish_parsing!
        return @current_test_suite
      end
  
      def start_test_suite(line)
        if @current_result.main_test_suite
          suite_name = line.match(/'(.*)'/)[1]
          started_at = Time.parse(line.match(/started at (.*)/)[1])
          @current_test_suite = TestResult::TestSuite.new(suite_name)
          @current_test_suite.start(started_at)
          @current_result.test_suites << @current_test_suite
        else
          suite_name = File.basename(line.match(/'(.*)'/)[1])
          started_at = Time.parse(line.match(/started at (.*)/)[1])
          @current_result.main_test_suite = TestResult::TestSuite.new(suite_name)
          @current_result.main_test_suite.start(started_at)
        end
      end
  
      def finish_test_suite(line)
        if @current_test_suite
          finished_at = Time.parse(line.match(/finished at (.*)/)[1])
          @current_test_suite.finish(finished_at)
          @current_test_suite = nil
        else
          finished_at = Time.parse(line.match(/finished at (.*)/)[1])
          @current_result.main_test_suite.finish(finished_at)
        end
      end
  
      def parse_test_case(line)
        test_name = line.match(/'.*\stest(.*)\]'/)[1]
        if line.match(/passed/)
          test_case = TestResult::TestCase.new(test_name, true)
        elsif line.match(/failed/)
          test_case = TestResult::TestCase.new(test_name, false)
          test_case.failure_message = @parser.previous_line.strip
        end
        @current_test_suite.test_cases << test_case
      end
    end
  
    class TestResult
      attr_accessor :main_test_suite
      attr_reader :test_suites
  
      def initialize
        @test_suites = []
      end
  
      def number_of_failures
        @test_suites.inject(0) do |sum, test_suite|
          sum + test_suite.number_of_failures
        end
      end
  
      def total_tests_run
        @test_suites.inject(0) do |sum, test_suite|
          sum + test_suite.test_cases.length
        end
      end
  
      def success?
        number_of_failures == 0
      end
  
      class TestSuite
        attr_reader :name
        attr_reader :started_at
        attr_reader :finished_at
        attr_reader :test_cases
    
        def initialize(name)
          @name = name
          @test_cases = []
        end
    
        def start(start_time)
          @started_at = start_time
        end
    
        def finish(finish_time)
          @finished_at = finish_time
        end
    
        def number_of_failures
          failing_tests.length
        end
    
        def failing_tests
          @test_cases.select { |tc| !tc.passed? }
        end
      end
  
      class TestCase
        attr_reader :name
        attr_accessor :failure_message
    
        def initialize(name, did_pass)
          @name = name
          @did_pass = did_pass
        end
    
        def passed?
          @did_pass
        end
      end
    end
    
  end
end