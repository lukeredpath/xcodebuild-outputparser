require 'term/ansicolor'

module Xcode
  module BuildParser
    class LiveOutputDelegate
      attr_reader :current_result
      attr_accessor :parser
      attr_reader :failures

      include Term::ANSIColor
  
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
          puts red { "  #{idx+1}) #{failure[:brief]}" }
          puts "  #{failure[:detail]}"
        end
        puts send(@failures.empty? ? :green : :red) { 
          "#{@tests_run} tests, #{@failures.length} failures" 
        }
      end

      def start_test_suite(line)
        suite_name = line.match(/'(.*)'/)[1]
        if suite_name !~ /TestCase/
          puts "Loaded suite #{suite_name}:"
        end
      end

      def finish_test_suite(line)
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
  end
end
