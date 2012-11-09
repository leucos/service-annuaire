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
end