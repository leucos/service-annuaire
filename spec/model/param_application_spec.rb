#encoding: utf-8

#coding: utf-8
require_relative '../helper'

describe ParamApplication do
  delete_test_users()
  delete_test_application()
  delete_test_etablissements()

  it "doesn't accept same code for the same application" do
  end

  it "destroy all param_user and param_etablissement on destroy" do
    app = create_test_application_with_param()
    u = create_test_user()
    e = create_test_etablissement()
    pref_id = app.param_application[0].id
    param_id = app.param_application[1].id

    ParamUser.create(:user => u, :param_application_id => pref_id, :valeur => 200)
    ParamEtablissement.create(:etablissement => e, :param_application_id => param_id, :valeur => 200)

    ParamApplication[pref_id].destroy()
    ParamUser.filter(:user => u).count.should == 0
    ParamApplication[param_id].destroy()
    ParamEtablissement.filter(:etablissement => e).count.should == 0
    delete_test_users()
    delete_test_application()
    delete_test_etablissements()
  end

  it "stocke les valeurs et autres valeurs sous un format json définit par type_param" do
    # Si c'est un number, on a min/max/increment
    # Si c'est une chaine on a min/max
    # Si c'est un boolean on rien ?
    # Si c'est multivalué on a un tableau avec les valeurs
  end

  it "on dispose d'api permettant d'accéder au min/max/increment/values etc." do
  end
end