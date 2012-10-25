#coding: utf-8
require_relative '../helper'

describe Service do
  Service.unrestrict_primary_key()

  it "declare_service_class raise an error with wrong service_id" do
    should.raise Service::NoServiceError do
      Service.declare_service_class("PROUT", User)
    end
  end

  it "create and destroy a ressource on creation/deletion" do
    s = Service.create(:id => "TEST", :api => true)
    Ressource[:service_id => SRV_SERVICE, :id => s.id].should.not == nil
    s.destroy()
    Ressource[:service_id => SRV_SERVICE, :id => s.id].should == nil
  end

  #Au cas où ça s'est mal passé
  Service["TEST"].destroy() if Service["TEST"]
end