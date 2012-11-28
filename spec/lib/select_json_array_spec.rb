#coding: utf-8
require_relative '../helper'

describe Sequel::Plugins::SelectJsonArray do
  it "Return a valid json array with string and numbers" do
    u = create_test_user
    e = u.add_email("test@laclasse.com")
    u.add_email("test2@laclasse.com")
    hash = User.select_json_array(:emails, {:email__id => "i_id", :email__adresse => "adresse"}).
      left_join(:email, :email__user_id => :user__id).
      filter(:login => u.login).naked.first
    expect{
      emails = JSON.parse(hash[:emails])
      emails.count.should == 2
      emails.first["id"].should == e.id
    }.to_not raise_error(JSON::ParserError)
  end
end