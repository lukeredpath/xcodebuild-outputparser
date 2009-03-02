require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), *%w[.. lib]))

require 'xcode_output_parser'

class XcodeTestOutputParserTest < Test::Unit::TestCase
  
  context "Parsing a single, empty build product test suite" do
    setup do
      @test_output = <<-TESTOUTPUT
        Test Suite '/Users/luke/Projects/iphone/squeemote/build/Development-iphonesimulator/Testing.app' started at 2009-03-02 19:04:02 +0000
        Test Suite '/Users/luke/Projects/iphone/squeemote/build/Development-iphonesimulator/Testing.app' finished at 2009-03-02 19:04:02 +0000.
        Executed 0 tests, with 0 failures (0 unexpected) in 0.00 (0.00) seconds
      TESTOUTPUT
      
      @parser = XcodeOutputParser::TestResultParser.new
    end

    should "return a TestResult" do
      assert_instance_of XcodeOutputParser::TestResult, @parser.parse_output(@test_output)
    end
    
    context "and that result" do
      setup do
        @result = @parser.parse_output(@test_output)
      end

      should "contain the main suite name" do
        assert_equal "Testing.app", @result.main_test_suite.name
      end
      
      should "contain the started at time for the main suite" do
        assert_equal Time.parse('2009-03-02 19:04:02 +0000'), @result.main_test_suite.started_at
      end
      
      should "contain the finished at time for the main suite" do
        assert_equal Time.parse('2009-03-02 19:04:02 +0000'), @result.main_test_suite.finished_at
      end
    end
  end
  
  context "Result of parsing a single product test suite with one sub-test suite with no test cases" do
    setup do
      test_output = <<-TESTOUTPUT
        Test Suite '/Users/luke/Projects/iphone/squeemote/build/Development-iphonesimulator/Testing.app' started at 2009-03-02 19:04:02 +0000
        
        Test Suite 'GTMTestCase' started at 2009-03-02 19:04:02 +0000
        Test Suite 'GTMTestCase' finished at 2009-03-02 19:04:02 +0000.
        Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
        
        Test Suite '/Users/luke/Projects/iphone/squeemote/build/Development-iphonesimulator/Testing.app' finished at 2009-03-02 19:04:02 +0000.
        Executed 0 tests, with 0 failures (0 unexpected) in 0.00 (0.00) seconds
      TESTOUTPUT

      @result = XcodeOutputParser::TestResultParser.new.parse_output(test_output)
    end

    should "contain the main test suite" do
      assert_not_nil @result.main_test_suite
    end
    
    should "contain the sub test suites" do
      assert_equal 1, @result.test_suites.length
    end
    
    context "and that sub test suite" do
      setup do
        @test_suite = @result.test_suites.first
      end

      should "have a name" do
        assert_equal "GTMTestCase", @test_suite.name
      end
      
      should "have a start time" do
        assert_equal Time.parse('2009-03-02 19:04:02 +0000'), @test_suite.started_at
      end
      
      should "have a finish time" do
        assert_equal Time.parse('2009-03-02 19:04:02 +0000'), @test_suite.finished_at
      end
    end
  end
  
end