#coding: utf-8
require_relative '../helper'

describe Service do
  # Finalement on ne peut pas mettre une erreur car si on est en train de créer
  # la ressource du service, on aura l'erreur alors qu'on ne veut pas
  # it "declare_service_class raise an error with wrong service_id" do
  #   should.raise Service::NoServiceError do
  #     Service.declare_service_class("PROUT", User)
  #   end
  # end

  it "create and destroy a ressource on creation/deletion" do
    s = Service.create(:id => "TEST", :api => true)
    Ressource[:service_id => SRV_SERVICE, :id => s.id].should.not == nil
    s.destroy()
    Ressource[:service_id => SRV_SERVICE, :id => s.id].should == nil
  end

  #Au cas où ça s'est mal passé
  Service["TEST"].destroy() if Service["TEST"]
end