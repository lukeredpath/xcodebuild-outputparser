require File.join(File.dirname(__FILE__), *%w[reporter_delegate])

module Xcode
  module BuildParser
    class UnitTestParser
      attr_reader :delegate
      attr_reader :previous_line
  
      def initialize(delegate = ReporterDelegate.new)
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
  end
end
