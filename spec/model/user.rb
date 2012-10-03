require_relative '../helper'

describe User do
  #In case of something went wrong
  User.filter(:login => 'test').destroy()
  
  it "knows what is a valid uid" do
    User.is_valid_id?("VAA60000").should.equal true
    User.is_valid_id?("VGX61569").should.equal true
    User.is_valid_id?("VAA6000").should.equal false
    User.is_valid_id?("VAA70000").should.equal false
    User.is_valid_id?("WAA60000").should.equal false
    User.is_valid_id?(12360000).should.equal false

  end

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
    # Sunday bloody sundaaayyy
    u2 = User.new(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test')
    u2.valid?.should == false
    User.filter(:login => 'test').destroy()
  end

  it "doesn't allow bad code_postal" do
    u = User.new(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test', :code_postal => "69380A")
    u.valid?.should == false
    u = User.new(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test', :code_postal => "6938")
    u.valid?.should == false
    u = User.new(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test', :code_postal => 69380)
    u.valid?.should == true
    u = User.new(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test', :code_postal => "69380")
    u.valid?.should == true
  end

  it "Hashes passwords on creation" do
    u = User.new(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test')
    # Attention a bien utiliser to_s sinon le test est validé
    u.password.to_s.should != "test"
    u.password.should == "test"
    # is_password? est un sinonyme de ==
    u.password.is_password?("test").should == true
    u.password.is_password?("a").should == false
  end

  it "store hashed passwords" do
    User.create(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test')
    u = User.filter(:login => 'test').first
    u.password.to_s.should != "test"
    u.password.should == "test"
    User.filter(:login => 'test').destroy()
  end

  it "handle password modification" do
    u = User.new(:login => 'test', :password => 'test', :nom => 'test', :prenom => 'test')
    u.password = "toto"
    u.password.to_s.should != "toto"
    u.password.should == "toto"
  end
end