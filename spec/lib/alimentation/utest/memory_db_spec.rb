#coding: utf-8
require_relative '../../../helper'

describe Alimentation::MemoryDb do
  it "Find the right number of data" do
    mem = Alimentation::MemoryDb.new([:test])
    mem[:test].push({:value => 5})
    mem[:test].push({:value => 5})
    mem[:test].push({:value => 7})
    mem[:test].filter({:value => 5}).length.should == 2
  end
end