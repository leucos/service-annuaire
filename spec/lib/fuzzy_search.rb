#coding: utf-8
require_relative '../helper'

describe Sequel::Plugins::FuzzySearch do
  it "find user based on several criters" do
    u = create_test_user("test")
    u2 = create_test_user("autre")
    # On utilise le model User qui utilise le plugin
    User.search([:login, :prenom], ["test"]).count.should == 2
    User.search([:login, :prenom], ["test", "autre"]).count.should == 1
  end
end