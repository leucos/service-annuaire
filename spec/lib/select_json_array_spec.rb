#coding: utf-8
require_relative '../helper'

describe Sequel::Plugins::SelectJsonArray do
  it "Return a valid json array with string and numbers" do
    u = create_test_user
    e = u.add_email("test@laclasse.com")
    u.add_email("test2@laclasse.com")
    hash = User.
      left_join(:email, :email__user_id => :user__id).
      select(:nom).
      select_json_array!(:emails, {:email__id => "i_id", :email__adresse => "adresse"}).
      filter(:login => u.login).first
    emails = hash[:emails]
    emails.count.should == 2
    emails.first["id"].should == e.id
    hash[:nom].should == "test"
  end
end