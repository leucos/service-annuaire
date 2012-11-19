#coding: utf-8
require_relative '../helper'

describe Application do
  it "remove all the parameter link to the application before destroy" do
    app = create_test_application_with_param()
    app_id = app.id
    app.param_application.count.should == 3
    app.destroy()
    ParamApplication.filter(:application_id => app_id).count.should == 0
  end
end