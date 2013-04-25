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

  it "returns all activities for a certain user" do
    # creat test role 
    r = Role.find_or_create(:id => "test_role")
    r.add_activite(SRV_USER, ACT_READ, "belongs_to", SRV_ETAB)
    r.add_activite(SRV_ETAB, ACT_READ, "belongs_to", SRV_ETAB)
    r.add_activite(SRV_CLASSE, ACT_DELETE, "belongs_to", SRV_ETAB)
    
    # attach le role avec un utilisateur  
    # create user with role on etablissement ressource  
    
    e1 = create_test_etablissement("etab1")
    e2 = create_test_etablissement("etab2")

    # create test user
    u = create_test_user("test_user")
   
    RoleUser.find_or_create(:user_id => u.id, :role_id => r.id, :etablissement_id => e1.id)

    #admin = create_user_with_role(r.id, e1.ressource)
    Rights.resolve_rights(u.id).should_not == []

  end  

  it "returns all activities for admin laclasse" do
    # creat admin_laclasse role 
    #r = create_admin_laclasse_role(@app.id)
    r = Role.find_or_create(:id =>"admin_laclasse")  
    #r = Role.find_or_create(:id => "admin_laclasse", :application_id => application_id)
    r.add_activite(SRV_USER, ACT_MANAGE, "all", SRV_LACLASSE)
    r.add_activite(SRV_ETAB, ACT_MANAGE, "all", SRV_LACLASSE)
    r.add_activite(SRV_CLASSE, ACT_MANAGE, "all", SRV_LACLASSE)
    r.add_activite(SRV_GROUPE, ACT_MANAGE, "all", SRV_LACLASSE)

    # attach le role avec un utilisateur 
    #admin = create_user_with_role(r.id)
    
    e1 = create_test_etablissement("etab 1")
    e2 = create_test_etablissement("etab 2")
    # may be create an etablissement for laclasse ?!
    admin = create_user_with_role_in_etab(r.id , e1.id)
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
    # create admin etab role
    r = Role.find_or_create(:id => "admnEtab")
    
    # create test etablissement e1
    e1 = create_test_etablissement("etab 1")

    # admin etab 
        # can :manage users that belongs to etablissement e1 
        # can :read, update e1
        # can :manage classes that belongs to e1 
        # can :manage groupes that belongs to e1 

    r.add_activite(SRV_USER, ACT_MANAGE, "belongs_to", SRV_ETAB)
    r.add_activite(SRV_ETAB, ACT_UPDATE, "belongs_to", SRV_ETAB)
    r.add_activite(SRV_ETAB, ACT_READ, "belongs_to", SRV_ETAB)
    r.add_activite(SRV_CLASSE, ACT_MANAGE, "belongs_to", SRV_ETAB)
    r.add_activite(SRV_GROUPE, ACT_MANAGE, "belongs_to", SRV_ETAB)
    
    #r.add_activite(SRV_ETAB, ACT_READ, "belongs_to", SRV_LACLASSE)
    r.add_activite(SRV_ETAB, ACT_READ, "all", SRV_LACLASSE)
    
    # On créer un deuxième etab
    e2 = create_test_etablissement("etab 2")
    #create a user with admnEtab role
    admin_etab = create_user_with_role_in_etab(r.id, e1.id)
    #puts Rights.find_rights(admin_etab.id).inspect

    # create a test classe
    c1 = create_class_in_etablissement(e1.id)

    #create test user in e1
    u1 = create_test_user_in_etab(e1.id, "user1")

    #puts Rights.find_rights(admin_etab.id).inspect
    #Rights.get_activities(admin_etab.id, e1.ressource.id, e1.ressource.service_id).should == [ACT_UPDATE, ACT_READ].sort
    # admin_etab has only read activities on e2 
    Rights.get_activities(admin_etab.id, e1.ressource.id, e1.ressource.service_id).should == [ACT_READ, ACT_UPDATE].sort
    Rights.get_activities(admin_etab.id, e2.ressource.id, e2.ressource.service_id).should == [ACT_READ]

    Rights.get_activities(admin_etab.id, c1.ressource.id, c1.ressource.service_id).should == [ACT_MANAGE]
    Rights.get_activities(admin_etab.id, u1.ressource.id, u1.ressource.service_id).should == [ACT_MANAGE]
    admin_etab.destroy
  end

  it "returns manage user activity  if user has Admin role on the etab" do 
    # create admin etab role
    r = Role.find_or_create(:id => "admnEtab")
    
    # create test etablissement e1
    e1 = create_test_etablissement("etab 1")
    # add activities to role admnEtab
    # can :manage Users belongs_to e1
    # can :manage Classes belongs_to e1 
    # can :manage groupes belongs_to e1 
    # can :update e1 
    # can :read e1 
    # can :read all Etabs belongs_to Laclasse 
    r.add_activite(SRV_USER, ACT_MANAGE, "belongs_to", SRV_ETAB)
    r.add_activite(SRV_ETAB, ACT_UPDATE, "belongs_to", SRV_ETAB)
    r.add_activite(SRV_ETAB, ACT_READ, "belongs_to", SRV_ETAB)
    r.add_activite(SRV_CLASSE, ACT_MANAGE, "belongs_to", SRV_ETAB)
    r.add_activite(SRV_GROUPE, ACT_MANAGE, "belongs_to", SRV_ETAB)
    r.add_activite(SRV_ETAB, ACT_READ, "belongs_to", SRV_LACLASSE)
    e2 = create_test_etablissement("etab 2")

    # add user to e1
    u1 = create_test_user_in_etab(e1.id, "user1")
    # add user to e2
    u2 = create_test_user_in_etab(e2.id, "user2")
    
    classe = create_class_in_etablissement(e1.id)
    #create role admin etablissement on etablissement e1
    admin_etab = create_user_with_role_in_etab(r.id, e1.id)
    #puts Rights.find_rights(admin_etab.id).inspect
    # admin_etab has activities on e1(self) 
    Rights.get_activities(admin_etab.id, e1.ressource.id, e1.ressource.service_id).should == [ACT_UPDATE, ACT_READ].sort
    Rights.get_activities(admin_etab.id, e2.ressource.id, e2.ressource.service_id).should == [ACT_READ]
    
    #admin_etab has activities on users (u1) that belongs to e1 but not on u2
    Rights.get_activities(admin_etab.id, u1.ressource.id, u1.ressource.service_id).should == [ACT_MANAGE]
    Rights.get_activities(admin_etab.id, u2.ressource.id, u2.ressource.service_id).should == []

    # admin_etab has activities on classes (class) that belongs to e1  
    Rights.get_activities(admin_etab.id, classe.ressource.id, classe.ressource.service_id).should == [ACT_MANAGE]
    
    admin_etab.destroy
    classe.destroy
  end

  it "returns right activites for a user with role prof in the etablissement" do 
    #r1 = create_prof_test_role_on_etab(@app.id)
    # create prof test role 
    prof_role = Role.find_or_create(:id => "prof")
    
    # create test etablissmenet e1 
    e1 = create_test_etablissement("etab 1")    

    # add activities related to etablissement e1
    prof_role.add_activite(SRV_USER, ACT_READ, "belongs_to", SRV_ETAB)
    prof_role.add_activite(SRV_CLASSE, ACT_READ, "belongs_to", SRV_ETAB)
    prof_role.add_activite(SRV_GROUPE, ACT_READ, "belongs_to", SRV_ETAB)
    prof_role.add_activite(SRV_ETAB, ACT_READ, "belongs_to",SRV_ETAB)

    # create another test etablissement e2
    e2 = create_test_etablissement("etab 2")

    # create test users u1, u2 
    u1 = create_test_user_in_etab(e1.id, "user1")
    u2 = create_test_user_in_etab(e1.id, "user2")

    # create test class c1 in e1 
    c1 = create_class_in_etablissement(e1.id)

    # add only u1 to c1 
    u1.add_to_regroupement(c1.id)

    #add activities related to class c1 
    prof_role.add_activite(SRV_USER, ACT_MANAGE, "belongs_to", SRV_CLASSE)
    prof_role.add_activite(SRV_CLASSE, ACT_READ, "belongs_to", SRV_CLASSE)
    prof_role.add_activite(SRV_CLASSE, ACT_UPDATE, "belongs_to", SRV_CLASSE)
    prof_role.add_activite(SRV_GROUPE, ACT_READ, "belongs_to", SRV_GROUPE)
    prof_role.add_activite(SRV_GROUPE, ACT_UPDATE, "belongs_to", SRV_GROUPE)

    prof = create_user_with_role_in_etab(prof_role.id, e1.id)

    # add prof to c1 
    EnseigneDansRegroupement.find_or_create(:regroupement_id => c1.id, :user_id => prof.id,
      :matiere_enseignee_id => "000400", :prof_principal => "O")


    Rights.get_activities(prof.id, c1.ressource.id, c1.ressource.service_id).should == [ACT_READ, ACT_UPDATE]

    # prof can manage elees in his class, group
    Rights.get_activities(prof.id, u1.ressource.id, u1.ressource.service_id).should == [ACT_MANAGE]
    Rights.get_activities(prof.id, u2.ressource.id, u2.ressource.service_id).should == [ACT_READ]
  end


  it "returns right activities for an eleve role in a class, groupe" do 
    #r = create_eleve_test_role(@app.id)
    # create admin etab role
    r = Role.find_or_create(:id => "eleve")
    #r = Role.create(:id => "admin_etab", :application_id => application_id)
    # create test etablissement e1
    e1 = create_test_etablissement("etab 1")

    # create test etablissement e2
    e2 = create_test_etablissement("etab 2")

    # add activities on etablissement level
    r.add_activite(SRV_ETAB, ACT_READ,   "belongs_to", SRV_ETAB)
    r.add_activite(SRV_CLASSE, ACT_READ, "belongs_to", SRV_ETAB)
    r.add_activite(SRV_GROUPE, ACT_READ, "belongs_to", SRV_ETAB)
    

    #create test eleve 
    u1 = create_test_user_in_etab(e1.id, "user1")

    # create another test eleve in e1 
    u2 = create_test_user_in_etab(e1.id, "user2")

    # create test eleve in e2 
    u3 = create_test_user_in_etab(e2.id, "user3")

    # create test classe
    c1 = create_class_in_etablissement(e1.id)
    
    # add activities on classe level 
    r.add_activite(SRV_CLASSE, ACT_READ, "belongs_to", SRV_CLASSE)
    r.add_activite(SRV_GROUPE, ACT_READ, "belongs_to", SRV_GROUPE)
    r.add_activite(SRV_USER, ACT_READ, "belongs_to", SRV_CLASSE)
    
    # add activities on user level
    r.add_activite(SRV_USER, ACT_UPDATE, "self", SRV_USER)
    r.add_activite(SRV_USER, ACT_READ, "self", SRV_USER)
    
    # add role eleve to u1 
    role_eleve = RoleUser.find_or_create(:user_id => u1.id, :role_id => r.id,:etablissement_id => e1.id)
    
    # add u1 to c1
    u1.add_to_regroupement(c1.id)
    u2.add_to_regroupement(c1.id)

    #puts Rights.find_rights(u1.id).inspect
    

    Rights.get_activities(u1.id, e1.ressource.id, e1.ressource.service_id).should == [ACT_READ]
    Rights.get_activities(u1.id, e2.ressource.id, e2.ressource.service_id).should == []

     # an eleve can read and update ressources that belongs to himself
    Rights.get_activities(u1.id, u1.ressource.id, u1.ressource.service_id).should == [ACT_READ, ACT_UPDATE]


    Rights.get_activities(u1.id, u2.ressource.id, u2.ressource.service_id).should == [ACT_READ]
    Rights.get_activities(u1.id, u3.ressource.id, u3.ressource.service_id).should == []

    Rights.get_activities(u1.id, c1.ressource.id, c1.ressource.service_id).should == [ACT_READ]
  end

  it "returns right activities for a parent of an eleve" do 
    # r = create_parent_test_role(@app.id)
    # create parent role that has the same rights as his enfants
    r = Role.find_or_create(:id => "parent") 

    # role parent
      # can :read etablissment in which he has a profil
      # can :read classes in the etablissement 
      # can :read groups in the etablissement
    r.add_activite(SRV_ETAB, ACT_READ,   "belongs_to", SRV_ETAB)
    r.add_activite(SRV_CLASSE, ACT_READ, "belongs_to", SRV_ETAB)
    r.add_activite(SRV_GROUPE, ACT_READ, "belongs_to", SRV_ETAB) 

    # add activities on classe level
    # can read classes of his child(ren)
    # can read groupes of his child(ren)
    # can read users in his child(ren) classes
    # can read his son info ?!
    r.add_activite(SRV_CLASSE, ACT_READ, "belongs_to", SRV_CLASSE)
    r.add_activite(SRV_GROUPE, ACT_READ, "belongs_to", SRV_GROUPE)
    r.add_activite(SRV_USER, ACT_READ, "belongs_to", SRV_CLASSE)


    #add activities on user level
    # can read himself 
    # can update himself 
    r.add_activite(SRV_USER, ACT_UPDATE, "self", SRV_USER)
    r.add_activite(SRV_USER, ACT_READ, "self", SRV_USER)


    # create first test etablissement
    e1 = create_test_etablissement("etab 1")

    # create second test etablissement
    e2 = create_test_etablissement("etab 2")
 
    # # create test classe 
    c1 = create_class_in_etablissement(e1.id)
    c2 = create_class_in_etablissement(e1.id)

    #  create test eleve 
    eleve = create_test_user_in_etab(e1.id, "eleve1")
    eleve.add_to_regroupement(c1.id)
   
    # create test parents 
    p1 = create_test_user("pere")
    p2 = create_test_user("mere")
    p1.add_profil(e1.id, PRF_PAR)
    p2.add_profil(e1.id, PRF_PAR)

    # add (pére) to eleve 
    eleve.add_parent(p1, TYP_REL_PERE)
    # add (mére) to eleve
    eleve.add_parent(p2, TYP_REL_MERE)

    role_parent = RoleUser.find_or_create(:user_id => p1.id, :role_id => r.id, :etablissement_id => e1.id)
    #puts Rights.find_rights(p1.id).inspect
    Rights.get_activities(p1.id, e1.ressource.id, e1.ressource.service_id).should == [ACT_READ]
    Rights.get_activities(p1.id, e2.ressource.id, e2.ressource.service_id).should == []

     # an eleve can read and update ressources that belongs to himself
    Rights.get_activities(p1.id, eleve.ressource.id, eleve.ressource.service_id).should == [ACT_READ]


    Rights.get_activities(p1.id, p1.ressource.id, p1.ressource.service_id).should == [ACT_READ, ACT_UPDATE]
    

    Rights.get_activities(p1.id, c1.ressource.id, c1.ressource.service_id).should == [ACT_READ]

    # how to say that p1 has the same rights as eleve 

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