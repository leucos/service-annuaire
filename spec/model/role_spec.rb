#coding: utf-8
require_relative '../helper'

describe Role do
  it "add an Activite to a Role" do
    r = Role.create(:id => ROL_TEST, :service_id => SRV_ETAB)
    r.add_activite(SRV_ETAB, ACT_CREATE)
    ActiviteRole.filter(:role => r, :service_id => SRV_ETAB).count.should == 1
  end
end