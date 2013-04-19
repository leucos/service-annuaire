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
    # admin laclasse  
      # can  :manage all ressources 
    Rights.get_activities(admin.id, e1.ressource.id, e1.ressource.service_id).should == [ACT_MANAGE]
    Rights.get_activities(admin.id, e2.ressource.id, e2.ressource.service_id).should == [ACT_MANAGE]
    Rights.get_activities(admin.id, u1.ressource.id, u1.ressource.service_id).should == [ACT_MANAGE]
    Rights.get_activities(admin.id, u2.ressource.id, u2.ressource.service_id).should == [ACT_MANAGE]
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
      # can :manage Users, belongs_to e1 
      # can :manage Classes  That belongs_to  e1 
      # can :manage all  Regroupements belongs_to  e1 
      # can :read  e1 (self)
      # can :update e1 (self)

    # admin_etab has activities on e1 
    Rights.get_activities(admin_etab.id, e1.id, e1.service_id).should == [ACT_UPDATE, ACT_READ].sort

    # admin_etab has no activities on e2 
    Rights.get_activities(admin_etab.id, e2.ressource.id, e2.ressource.service_id).should == [ACT_READ]
    admin_etab.destroy
  end

  it "returns manage user activity  if user has Admin role on the etab" do 
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

    # admin_etab has activities on e1(self) 
    Rights.get_activities(admin_etab.id, e1.ressource.id, e1.ressource.service_id).should == [ACT_UPDATE, ACT_READ].sort
    Rights.get_activities(admin_etab.id, e2.ressource.id, e2.ressource.service_id).should == []
    
    #admin_etab has activities on users (u1) that belongs to e1 but not on u2
    Rights.get_activities(admin_etab.id, u1.ressource.id, u1.ressource.service_id).should == [ACT_MANAGE]
    Rights.get_activities(admin_etab.id, u2.ressource.id, u2.ressource.service_id).should == []

    # admin_etab has activities on classes (class) that belongs to e1  
    Rights.get_activities(admin_etab.id, classe.ressource.id, classe.ressource.service_id).should == [ACT_MANAGE]
    
    admin_etab.destroy
    classe.destroy
  end

  it "returns right activites for a prof role in etablissement" do 
    r1 = create_prof_test_role_on_etab(@app.id)
    e1 = create_test_etablissement("etab 1")
    e2 = create_test_etablissement("etab 2")

    # add user to e1
    u1 = create_test_user_in_etab(e1.id, "user1")
    
    u2 = create_test_user_in_etab(e1.id, "user2")

    # create test class c1 in e1 
    c1 = create_class_in_etablissement(e1.id)

    # add only u1 to c1 
    u1.add_to_regroupement(c1.id)

   # [{:activite=>"MANAGE", :subject_class=>"USER", :subject_id=>"416", :condition=>"belongs_to", :parent_class=>"CLASSE", :parent_id=>"119"}, 
   #  {:activite=>"READ", :subject_class=>"CLASSE", :subject_id=>"416", :condition=>"parent", :parent_class=>"CLASSE", :parent_id=>"119"}, 
   #  {:activite=>"READ", :subject_class=>"GROUPE", :subject_id=>"416", :condition=>"parent", :parent_class=>"CLASSE", :parent_id=>"119"}, 
   #  {:activite=>"READ", :subject_class=>"CLASSE", :subject_id=>"416", :condition=>"belongs_to", :parent_class=>"ETAB", :parent_id=>"284"}, 
   #  {:activite=>"READ", :subject_class=>"ETAB", :subject_id=>"416", :condition=>"parent", :parent_class=>"ETAB", :parent_id=>"284"}, 
   #  {:activite=>"READ", :subject_class=>"GROUPE", :subject_id=>"416", :condition=>"belongs_to", :parent_class=>"ETAB", :parent_id=>"284"},
   #  {:activite=>"READ", :subject_class=>"USER", :subject_id=>"416", :condition=>"belongs_to", :parent_class=>"ETAB", :parent_id=>"284"}]

    # create prof role on etablissement e1 
    # prof role 
    # can :read e1 
    # can :read, update User (self)
    # can :manage User(belongs_to)
    # can :read, update Class(belongs_to)
    prof = create_user_with_role(r1.id, e1.ressource)
    r2 = create_prof_test_role_on_class(@app.id)
    # add role prof class on c1 
    RoleUser.create(:user_id => prof.id, 
      :ressource_id => c1.ressource.id, :ressource_service_id => c1.ressource.service_id,
      :role_id => r2.id)
    
    puts Rights.find_rights(prof.id).inspect 
    Rights.get_activities(prof.id, c1.ressource.id, c1.ressource.service_id).should == [ACT_READ, ACT_UPDATE]

    # prof can manage elees in his class, group
    Rights.get_activities(prof.id, u1.ressource.id, u1.ressource.service_id).should == [ACT_MANAGE]
    Rights.get_activities(prof.id, u2.ressource.id, u2.ressource.service_id).should == []
  end


  it "returns right activites for a prof role on a class", :broken => true do 
    r = create_prof_test_role(@app.id)
    e1 = create_test_etablissement("etab 1")
    e2 = create_test_etablissement("etab 2")

    # add user to e1
    u1 = create_test_user_in_etab(e1.id, "user1")
    
    u2 = create_test_user_in_etab(e1.id, "user2")

    # create test class c1 in e1 
    c1 = create_class_in_etablissement(e1.id)

    # add only u1 to c1 
    u1.add_to_regroupement(c1.id)

    # create prof role on classe c1 
    prof = create_user_with_role(r.id, c1.ressource)
    
    #puts Rights.find_rights(prof.id).inspect 
    Rights.get_activities(prof.id, c1.ressource.id, c1.ressource.service_id).should == [ACT_READ]

    # prof can manage elees in his class, group
    Rights.get_activities(prof.id, u1.ressource.id, u1.ressource.service_id).should == [ACT_MANAGE]
    Rights.get_activities(prof.id, u2.ressource.id, u2.ressource.service_id).should == []
  end

  it "returns right activities for an eleve role in a class, groupe" do 
    r = create_eleve_test_role(@app.id)
    e1 = create_test_etablissement("etab 1")

    #create test eleve 
    u1 = create_test_user_in_etab(e1.id, "user1")

    # create test classe
    c1 = create_class_in_etablissement(e1.id)

    # add role eleve to u1 
    RoleUser.create(:user_id => u1.id, 
      :ressource_id => c1.ressource.id, :ressource_service_id => c1.ressource.service_id,
      :role_id => r.id)
    # an eleve can read and update ressources that belongs to himself
    Rights.get_activities(u1.id, u1.ressource.id, u1.ressource.service_id).should == [ACT_READ, ACT_UPDATE]
    Rights.get_activities(u1.id, c1.ressource.id, c1.ressource.service_id).should == [ACT_READ]
  end

  it "returns right activities for a parent of an eleve " do 
    # r = create_parent_test_role(@app.id)
    # e1 = create_test_etablissement("etab 1")

    # # create test eleve 
    # eleve = create_test_user_in_etab(e1.id, "eleve1")
    
    # # create test classe 
    # c1 = create_class_in_etablissement(e1.id)

    # # create test parent 
    # parent = create_test_parent_in_etab(e1.id)
    # # add relation parent eleve
    # parent
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