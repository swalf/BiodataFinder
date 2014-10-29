# To change this template, choose Tools | Templates
# and open the template in the editor.

#$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'indexer'
require 'elasticsearch'

class Test_indexer < Test::Unit::TestCase
  def test_index
    test_client = Elasticsearch::Client.new log: true
    test_indexer = Indexer.new test_client "test_index"
    sample_files = (Dir.entries "./samplefiles/").select {|el| File(el).file?}
    sample_files.each {|filepath| test_indexer.index filepath}
        
    # assert_equal("foo", bar)
  end
end
