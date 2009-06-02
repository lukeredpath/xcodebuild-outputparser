require 'time'

module XcodeOutputParser
  class TestResultParser
    attr_reader :delegate
    attr_reader :previous_line
    
    def initialize(delegate = TestResultLineParserDelegate.new)
      @delegate = delegate
      @delegate.parser = self
      @previous_line = nil
    end
    
    def self.open(path)
      result = nil
      File.open(path) do |io|
        parser = self.new
        result = parser.parse_output(io.read)
      end
      result
    end

    def parse_output(test_output)
      @delegate.start_parsing!
      test_output.split("\n").each do |line|
        parse_line(line)
      end
      @delegate.current_result
    end
    
    def parse_output_from_command(cmd)
      @delegate.start_parsing!
      IO.popen(cmd) do |io|
        loop do
          begin
            parse_line(io.readline)
          rescue EOFError
            break
          end
        end
      end
      @delegate.finish_parsing!
    end
    
    def parse_line(line)
      if line.strip =~ /^Test Suite(.*)started/
        @delegate.start_test_suite(line)
      end
      if line.strip =~ /^Test Suite(.*)finished/
        @delegate.finish_test_suite(line)
      end
      if line.strip =~ /^Test Case/
        @delegate.parse_test_case(line)
      end
      @previous_line = line
    end
  end
  
  class TestResultLineParserDelegate
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