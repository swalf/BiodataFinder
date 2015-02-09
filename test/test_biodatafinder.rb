# To change this template, choose Tools | Templates
# and open the template in the editor.

#$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'minitest/autorun'
require_relative '../lib/biodatafinder.rb'


class Test_core < Minitest::Test
    

  def setup
    p 'Setup:'
  end
  
  def test_cliquery
	test_client = Biodatafinder::Client.new 'http://localhost:9220', 'test-idx', false
	test_client.parse 'sample_files/example.gtf'
	
#     assert_equal(Array, @res.class, "il risultato non è un array")
#     
#     @res.each_with_index { |el, i|  assert_equal(String,el.class, "il #{i+1} elemento di res non è una stringa")}
#     
        
    
    
  end
end
