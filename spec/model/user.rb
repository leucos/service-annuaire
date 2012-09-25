require_relative '../helper'

describe User do
  #In case of something went wrong
  User.filter(:login => 'test').destroy()
  
  it "gives the good next id to user even after a destroy" do
    last_id = DB[:last_uid].first[:last_uid]
    awaited_next_id = UidGenerator.increment(last_id)

    u = User.create(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test')
    u.id.should == awaited_next_id
    User.filter(:login => 'test').destroy()

    awaited_next_id = UidGenerator.increment(awaited_next_id)
    u = User.create(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test')
    u.id.should == awaited_next_id
    User.filter(:login => 'test').destroy()
  end

  it "doesn't allow duplicated logins" do
    u = User.create(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test')
    should.raise(Sequel::ValidationFailed) do
      u = User.create(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test')
    end
    User.filter(:login => 'test').destroy()
  end
end