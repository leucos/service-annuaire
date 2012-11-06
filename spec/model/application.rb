#coding: utf-8
require_relative '../helper'

describe Application do
  delete_test_application()

  it "remove all the parameter link to the application before destroy" do
    app = create_test_application_with_param()
    app_id = app.id
    app.param_application.count.should == 1
    app.destroy()
    ParamApplication.filter(:application_id => app_id).count.should == 0
  end
end