#coding: utf-8
require_relative '../helper'

describe Email do
  include Mail::Matchers

  it "Send an email for validate the adress" do
    u = create_test_user()
    email = u.add_email("test@test.com")
    validation_key = email.generate_validation_key()
    validation_key = "#{REDIS_PATH}.#{EMAIL_PATH}.#{validation_key}"
    REDIS.get(validation_key).to_i.should == email.id
    REDIS.ttl(validation_key).should > EMAIL_DURATION - 10
    REDIS.ttl(validation_key).should <= EMAIL_DURATION
  end

  it "check_validation_key remove the redis key and set valide at TRUE" do
    u = create_test_user()
    email = u.add_email("test@test.com")
    Email[email.id].valide.should == false
    validation_key = email.generate_validation_key()
    email.check_validation_key(validation_key).should == true
    email.check_validation_key(validation_key).should == false
    Email[email.id].valide.should == true
  end

  it "send a validation email" do
    u = create_test_user()
    email = u.add_email("test@test.com")
    email.send_validation_mail()
    should have_sent_email.from('noreply@laclasse.com')
    should have_sent_email.to(email.adresse)
  end
end