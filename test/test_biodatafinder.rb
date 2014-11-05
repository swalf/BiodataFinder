# To change this template, choose Tools | Templates
# and open the template in the editor.

#$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'minitest/autorun'
require "../sources/indexer.rb"
require "../sources/finder.rb"
require 'elasticsearch'

class Test_indexer < Minitest::Test
    
#  def test_index
#    test_client = Elasticsearch::Client.new log: true
#    test_indexer = Indexer.new test_client "test_index"
#    sample_files = (Dir.entries "./samplefiles/").select {|el| File(el).file?}
#    sample_files.each {|filepath| test_indexer.index filepath}
#    test_client.search index: "test_index", q: query_text   
#    # assert_equal("foo", bar)
#  end
  def setup
        
    @test_client = Elasticsearch::Client.new log: true
    @test_finder = (Finder.new @test_client, "a3")
    @res = @test_finder.query "TSS8"
  end
  
  def test_cliquery
    
    assert_equal(Array, @res.class, "il risultato non è un array")
    
    @res.each_with_index { |el, i|  assert_equal(String,el.class, "il #{i+1} elemento di res non è una stringa")}
    
        
    
    
  end
end
