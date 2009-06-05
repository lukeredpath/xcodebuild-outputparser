#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), *%w[.. lib xcode_output_parser])
require 'rubygems'
require 'term/ansicolor'

BUILD_COMMAND = "xcodebuild -target 'Unit Tests' -sdk iphonesimulator2.2 2> /dev/null"

module Colorize
  class << self
    include Term::ANSIColor
  
    def puts(color, string)
      Kernel.puts send(color) + string + reset
    end
  end
end



delegate = TestResultLiveOutputDelegate.new
parser = XcodeOutputParser::TestResultParser.new(delegate)
parser.parse_output_from_command(BUILD_COMMAND)
exit 1 if delegate.failures.length > 0
