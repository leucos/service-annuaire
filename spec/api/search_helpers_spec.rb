#coding: utf-8
require_relative '../helper'

describe SearchHelpers do
  include SearchHelpers
  it "split comme il faut" do
    split_query("nom:\"Georges Charpack\" test \"jean\" \"asta la vista baby\" prenom:\"Jean Claude\"").should == 
      ["nom:Georges Charpack", "test", "jean", "asta la vista baby", "prenom:Jean Claude"]
  end
end