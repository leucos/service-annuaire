#coding: utf-8
require_relative '../helper'

describe Telephone do
  delete_test_users()
  it "check the numero format" do
    u = create_test_user()
    should.not.raise Sequel::ValidationFailed do
      Telephone.create(:numero => "0478963214", :user => u, :type_telephone_id => TYP_TEL_MAIS)
    end

    should.not.raise Sequel::ValidationFailed do
      Telephone.create(:numero => "04 78 96 32 14", :user => u, :type_telephone_id => TYP_TEL_MAIS)
    end

    should.not.raise Sequel::ValidationFailed do
      Telephone.create(:numero => "+00334 78 96 32 14", :user => u, :type_telephone_id => TYP_TEL_MAIS)
    end

    should.not.raise Sequel::ValidationFailed do
      Telephone.create(:numero => "+00334-78-96-32-14", :user => u, :type_telephone_id => TYP_TEL_MAIS)
    end

    should.raise Sequel::ValidationFailed do
      Telephone.create(:numero => "+00334 78 96 32 14 21", :user => u, :type_telephone_id => TYP_TEL_MAIS)
    end

    should.raise Sequel::ValidationFailed do
      Telephone.create(:numero => "*00334-78-96-32-14", :user => u, :type_telephone_id => TYP_TEL_MAIS)
    end
    delete_test_users()
  end
end