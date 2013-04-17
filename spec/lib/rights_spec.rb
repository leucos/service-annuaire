#coding: utf-8
require_relative '../helper'


describe Rights do
  
  before :all do
    #create test application
    delete_test_application
    @app = create_test_application_with_param
  end

  after :each do 
    
  end 

  it "returns all activities for admin laclasse" do
    r = create_admin_laclasse_role(@app.id)
    admin = create_user_with_role(r.id)
    e1 = create_test_etablissement("etab 1")
    e2 = create_test_etablissement("etab 2")

    # add user to e1
    u1 = create_test_user_in_etab(e1.id, "user1")
    # add user to e2
    u2 = create_test_user_in_etab(e2.id, "user2")
    classe = create_class_in_etablissement(e1.id)
    puts Rights.get_activities(admin.id, e1.ressource.id, e1.ressource.service_id).inspect

  end

  it "returns update, read  activites for user on ressource etablissement if user has Admin role on the etab" do
    r = create_admin_etab_test_role(@app.id)
    e1 = create_test_ressources_tree()
    # On créer un deuxième etab
    e2 = Etablissement.create(:nom => "test", :type_etablissement => TypeEtablissement.first)

    #create role admin etablissement on etablissement e1
    admin_etab = create_user_with_role(r.id, e1)

    
    # example admin etablissement
    # admin on e1
      # can :create CREATE  Users, belongs_to e1 
      # can :delete Classes  That belongs_to  e1 
      # can :manage all  Regroupements belongs_to  e1 
      # can :read  e1 (self)
      # can :update e1 (self)

    # admin_etab has activities on e1 
    Rights.get_activities(admin_etab.id, e1.id, e1.service_id).should == [ACT_UPDATE, ACT_READ].sort

    # admin_etab has no activities on e2 
    Rights.get_activities(admin_etab.id, e2.ressource.id, e2.ressource.service_id).should == []
    #Rights.get_rights(admin.id, SRV_ETAB, e2.id, SRV_USER).should == []
    admin_etab.destroy
  end

  it "returns create user activity  if user has Admin role on the etab" do 
    r = create_admin_etab_test_role(@app.id)
    e1 = create_test_etablissement("etab 1")
    e2 = create_test_etablissement("etab 2")

    # add user to e1
    u1 = create_test_user_in_etab(e1.id, "user1")
    # add user to e2
    u2 = create_test_user_in_etab(e2.id, "user2")
    
    classe = create_class_in_etablissement(e1.id)
    #create role admin etablissement on etablissement e1
    admin_etab = create_user_with_role(r.id, e1.ressource)

    # Rights.find_rights(admin_etab.id)
    # r.add_activite(SRV_USER, ACT_READ, "belongs_to")
    # r.add_activite(SRV_USER, ACT_UPDATE, "belongs_to")
    # r.add_activite(SRV_USER, ACT_CREATE, "belongs_to")
    # r.add_activite(SRV_USER, ACT_DELETE, "belongs_to")
    # r.add_activite(SRV_ETAB, ACT_UPDATE, "self")
    # r.add_activite(SRV_ETAB, ACT_READ, "self")
    # r.add_activite(SRV_CLASSE, ACT_READ, "belongs_to")
    # r.add_activite(SRV_CLASSE, ACT_DELETE, "belongs_to")

    # admin_etab has activities on e1(self) 
    Rights.get_activities(admin_etab.id, e1.ressource.id, e1.ressource.service_id).should == [ACT_UPDATE, ACT_READ].sort
    Rights.get_activities(admin_etab.id, e2.ressource.id, e2.ressource.service_id).should == []
    
    #admin_etab has activities on users (u1) that belongs to e1 but not on u2
    Rights.get_activities(admin_etab.id, u1.ressource.id, u1.ressource.service_id).should == [ACT_UPDATE, ACT_READ, ACT_DELETE, ACT_CREATE].sort
    Rights.get_activities(admin_etab.id, u2.ressource.id, u2.ressource.service_id).should == []

    # admin_etab has activities on classes (class) that belongs to e1  
    Rights.get_activities(admin_etab.id, classe.ressource.id, classe.ressource.service_id).should == [ACT_READ, ACT_DELETE, ACT_CREATE].sort
    
    admin_etab.destroy
    classe.destroy
  end 

  it "return create_user rights for user in ressource etablissement if user has role on laclasse", :broken => true do
    r = create_test_role()
    ressource_etab = create_test_ressources_tree()
    # On créer un deuxième etab
    e2 = Etablissement.create(:nom => "test", :type_etablissement => TypeEtablissement.first)
    admin = create_user_with_role(r.id)
    Rights.get_rights(admin.id, SRV_ETAB, ressource_etab.id, SRV_USER).should == [ACT_CREATE]
    Rights.get_rights(admin.id, SRV_ETAB, e2.id, SRV_USER).should == [ACT_CREATE]
  end

  it "should return create rights for user on resource class if user has role on etab" , :broken => true do
    r = create_test_role()
    e = create_test_etablissement()
    admin = create_user_with_role(r.id, e.ressource)
    classe = e.add_regroupement({:type_regroupement_id => TYP_REG_CLS})
    Rights.get_rights(admin.id, SRV_CLASSE, classe.id).should == [ACT_DELETE]
  end

  it "should handle merge similar rights", :broken => true do
    # On donne des droits sur un établissement et sur laclasse
    r = create_test_role()
    e = create_test_etablissement()
    admin = create_user_with_role(r.id)
    RoleUser.create(:user_id => admin.id, 
      :ressource_id => e.ressource.id, :ressource_service_id => e.ressource.service_id,
      :role_id => r.id)
    Rights.get_rights(admin.id, SRV_ETAB, e.ressource.id, SRV_USER).should == [ACT_CREATE]
  end

  it "should return create rights on service user for laclasse admin",:broken => true do
    r = create_test_role()
    admin = create_user_with_role(r.id)
    laclasse_id = Ressource[:service_id => SRV_LACLASSE].id
    Rights.get_rights(admin.id, SRV_LACLASSE, laclasse_id, SRV_USER).should == [ACT_CREATE]
  end

  it "cumulate rights from different role", :broken => true do
    r = create_test_role()
    e = create_test_etablissement()
    # On donne un role sur l'établissement
    admin = create_user_with_role(r.id, e.ressource)
    r = Role.find_or_create(:id => "TEST2", :service_id => SRV_CLASSE)
    ActiviteRole.find_or_create(:service_id => SRV_CLASSE, :role_id => r.id, :activite_id => ACT_UPDATE)
    classe = e.add_regroupement({:type_regroupement_id => TYP_REG_CLS})
    # Puis un role sur la classe
    admin.add_role(classe.id, SRV_CLASSE, r.id)

    # On doit cumuler les role de l'établissement et du groupe
    Rights.get_rights(admin.id, SRV_CLASSE, classe.id).sort.should == [ACT_DELETE, ACT_UPDATE]
    
    # Maintenant si j'enlève le role sur la classe et que je le rajoute sur l'établissement
    RoleUser.filter(:ressource_id => classe.id, :ressource_service_id => SRV_CLASSE).destroy()
    admin.add_role(e.id, SRV_ETAB, r.id)
    
    # Ca doit faire pareil
    Rights.get_rights(admin.id, SRV_CLASSE, classe.id).sort.should == [ACT_DELETE, ACT_UPDATE]

    r.destroy()
  end

  # todo : Tester que l'on puisse accéder aux fichiers d'un établissement mais pas à celui des classes
  # notion de service_parent_id
  
end