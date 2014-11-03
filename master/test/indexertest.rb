# To change this template, choose Tools | Templates
# and open the template in the editor.

#$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'indexer'
require 'elasticsearch'

class Test_indexer < Test::Unit::TestCase
    
#  def test_index
#    test_client = Elasticsearch::Client.new log: true
#    test_indexer = Indexer.new test_client "test_index"
#    sample_files = (Dir.entries "./samplefiles/").select {|el| File(el).file?}
#    sample_files.each {|filepath| test_indexer.index filepath}
#    test_client.search index: "test_index", q: query_text   
#    # assert_equal("foo", bar)
#  end
  
  def test_cliquery
    test_client = Elasticsearch::Client.new log: true
    test_clif = CLIFinder.new test_client "a3"
    test_clif.query "TSS8"
  end
end
