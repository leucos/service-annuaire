#coding: utf-8
require_relative '../helper'

describe Telephone do
  delete_test_users()
  it "check the numero format" do
    u = create_test_user()
    expect {
      Telephone.create(:numero => "0478963214", :user => u, :type_telephone_id => TYP_TEL_MAIS)
    }.to_not raise_error(Sequel::ValidationFailed)

    expect {
      Telephone.create(:numero => "04 78 96 32 14", :user => u, :type_telephone_id => TYP_TEL_MAIS)
    }.to_not raise_error(Sequel::ValidationFailed)

    expect {
      Telephone.create(:numero => "+00334 78 96 32 14", :user => u, :type_telephone_id => TYP_TEL_MAIS)
     }.to_not raise_error(Sequel::ValidationFailed)

    expect {
      Telephone.create(:numero => "+00334-78-96-32-14", :user => u, :type_telephone_id => TYP_TEL_MAIS)
     }.to_not raise_error(Sequel::ValidationFailed)

    expect {
      Telephone.create(:numero => "+00334 78 96 32 14 21", :user => u, :type_telephone_id => TYP_TEL_MAIS)
     }.to raise_error(Sequel::ValidationFailed)

    expect {
      Telephone.create(:numero => "*00334-78-96-32-14", :user => u, :type_telephone_id => TYP_TEL_MAIS)
     }.to raise_error(Sequel::ValidationFailed)
  end
end