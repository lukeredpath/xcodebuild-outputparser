require 'time'

module XcodeOutputParser
  class TestResultParser
    def self.open(path)
      result = nil
      File.open(path) do |io|
        parser = self.new
        result = parser.parse_output(io.read)
      end
      result
    end

    def parse_output(test_output)
      start_parsing!
      test_output.split("\n").each do |line|
        if line.strip =~ /^Test Suite(.*)started/
          if @current_result.main_test_suite
            start_test_suite(line)
          else
            start_main_test_suite(line)
          end
        end
        if line.strip =~ /^Test Suite(.*)finished/
          if @current_test_suite
            finish_test_suite(line)
          else
            finish_main_test_suite(line)
          end
        end
        if line.strip =~ /^Test Case/
          parse_test_case(line)
        end
        @previous_line = line
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
    
    def parse_test_case(line)
      test_name = line.match(/'.*\stest(.*)\]'/)[1]
      if line.match(/passed/)
        test_case = TestResult::TestCase.new(test_name, true)
      elsif line.match(/failed/)
        test_case = TestResult::TestCase.new(test_name, false)
        test_case.failure_message = @previous_line.strip
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
        @test_cases.select { |tc| !tc.passed? }.length
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