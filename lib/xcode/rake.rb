require 'rake'
require 'rake/tasklib'
require File.join(File.dirname(__FILE__), *%w[.. xcode_output_parser])
require File.join(File.dirname(__FILE__), *%w[live_output_delegate])

module Xcode
  module Rake
    class BuildTask < ::Rake::TaskLib
      attr_accessor :name
      attr_accessor :project
      attr_accessor :target
      attr_accessor :configuration
      attr_accessor :sdk
    
      def initialize(name = :build)
        @name = name
        yield self if block_given?
        define
      end
    
      def define
        task name do
          system(command_string)
        end
      end
      
      protected
      
      def command_string
        %{
          xcodebuild \
            -sdk '#{sdk}'\
            -configuration '#{configuration}'\
            -target '#{target}'
        }
      end
    end
    
    class TestTask < BuildTask
      def define
        task name do
          parser_delegate = Xcode::BuildParser::LiveOutputDelegate.new
          parser = XcodeOutputParser::TestResultParser.new(parser_delegate)
          parser.parse_output_from_command(command_string)
          parser_delegate.failures.length == 0
        end
      end
    end
  end
end