Given /^the RFC 4566 SDP example in a file$/ do
  @sdp_file = File.open(File.dirname(__FILE__) + '/../support/sdp_file.txt', 'r').read
end

When /^I parse the file$/ do
  @sdp = SDP.parse_sdp @sdp_file
  require 'ap'
  ap @sdp
end

Then /^the <value> for <field> is accessible via <rubyfied>$/ do |table|
  # table is a Cucumber::Ast::Table
  table.hashes.each do |hash|
    #jfield_to_hash_key(hash["rubyfied"])
    # @sdp[]
    key = hash["rubyfied"]
puts "key: #{key}"
puts "key class: #{key.class}"
    #@sdp.fetch(key).should == hash["value"]
    @sdp.send(:fetch, key).should == hash["value"]
  end
end

require 'strscan'
def field_to_hash_key field
  #string = StringScanner.new(field)
  words = field.scan(/\w+/)
    
end
