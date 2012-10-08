#coding: utf-8
require 'ramaze'
require 'ramaze/spec/bacon'
require 'json'

require_relative '../app'

def create_test_user(login = "test")
  User.create(:login => login, :password => 'test', :nom => 'test', :prenom => 'test')
end

def new_test_user(login = "test")
  User.new(:login => login, :password => 'test', :nom => 'test', :prenom => 'test')
end

def delete_test_users()
  User.filter(:nom => "test", :prenom => 'test').delete()
  User.filter(:login => "test").delete()
end

def create_test_eleve(login = "eleve")

end