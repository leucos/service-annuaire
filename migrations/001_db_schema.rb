Sequel.migration do
  change do
    create_table(:activite) do
      String :id, :size=>45, :null=>false
      String :libelle, :size=>255
      String :description, :size=>1024
      
      primary_key [:id]
    end
    
    create_table(:application) do
      String :id, :size=>8, :fixed=>true, :null=>false
      String :libelle, :size=>255
      String :description, :size=>500
      String :url, :size=>2000, :null=>false
      TrueClass :active, :default=>true
      
      primary_key [:id]
    end
    
    create_table(:fonction) do
      primary_key :id
      String :libelle, :size=>45
      String :description, :size=>100
      String :code_men, :size=>20
    end
    
    create_table(:last_uid) do
      String :last_uid, :size=>8, :fixed=>true
    end
    
    create_table(:matiere_enseignee) do
      String :id, :size=>10, :null=>false
      String :libelle_court, :size=>45
      String :libelle_long, :size=>255
      
      primary_key [:id]
    end
    
    create_table(:niveau) do
      String :ent_mef_jointure, :size=>20, :null=>false
      String :mef_libelle, :size=>256
      String :ent_mef_rattach, :size=>20
      String :ent_mef_stat, :size=>20
      
      primary_key [:ent_mef_jointure]
    end
    
    create_table(:publipostage) do
      primary_key :id
      DateTime :date
      String :message, :text=>true
      String :profils, :size=>255
      TrueClass :difusion_email, :default=>false
      TrueClass :difusion_pdf, :default=>false
      TrueClass :difusion_notif, :default=>false
      String :message_type, :size=>45
      String :descriptif, :default=>"\"\"", :size=>255
      String :personnels, :text=>true
    end
    
    create_table(:reserved_uid) do
      String :reserved_uid, :size=>8, :fixed=>true, :null=>false
      
      primary_key [:reserved_uid]
    end
    
    create_table(:role) do
      String :id, :size=>20, :null=>false
      String :libelle, :size=>45
      String :description, :size=>255
      Integer :priority, :default=>0, :null=>false
      
      primary_key [:id]
    end
    
    create_table(:service) do
      String :id, :size=>8, :fixed=>true, :null=>false
      String :libelle, :size=>255
      String :description, :size=>1024
      String :url, :size=>1024
      
      primary_key [:id]
    end
    
    create_table(:type_etablissement) do
      primary_key :id
      String :nom, :size=>255
      String :type_contrat, :size=>10
      String :libelle, :size=>255
      String :type_struct_aaf, :size=>255
    end
    
    create_table(:type_param) do
      String :id, :size=>8, :fixed=>true, :null=>false
      
      primary_key [:id]
    end
    
    create_table(:type_regroupement) do
      String :id, :size=>8, :fixed=>true, :null=>false
      String :libelle, :size=>45
      String :description, :size=>255
      
      primary_key [:id]
    end
    
    create_table(:type_relation_eleve) do
      primary_key :id
      String :description, :size=>45
      String :libelle, :size=>10, :null=>false
    end
    
    create_table(:type_telephone) do
      String :id, :size=>8, :fixed=>true, :null=>false
      String :libelle, :size=>45
      String :description, :size=>255
      
      primary_key [:id]
    end
    
    create_table(:user, :ignore_index_errors=>true) do
      primary_key :id
      Integer :id_sconet
      Integer :id_jointure_aaf
      String :login, :size=>45
      String :password, :size=>60, :fixed=>true
      String :nom, :size=>45, :null=>false
      String :prenom, :size=>45, :null=>false
      String :sexe, :size=>1
      Date :date_naissance
      String :adresse, :size=>255
      String :code_postal, :size=>6, :fixed=>true
      String :ville, :size=>255
      Date :date_creation, :null=>false
      Date :date_debut_activation
      Date :date_fin_activation
      DateTime :date_derniere_connexion
      TrueClass :bloque, :default=>false, :null=>false
      TrueClass :change_password, :default=>false
      String :id_ent, :size=>16, :fixed=>true, :null=>false
      String :avatar, :default=>"empty", :size=>255, :null=>false
      
      index [:id_ent], :name=>:id_ent_UNIQUE
      index [:id_jointure_aaf], :name=>:id_jointure_aaf_UNIQUE
      index [:id_sconet], :name=>:id_sconet_UNIQUE, :unique=>true
      index [:login], :name=>:login_UNIQUE, :unique=>true
    end
    
    create_table(:activite_role, :ignore_index_errors=>true) do
      foreign_key :activite_id, :activite, :type=>String, :size=>45, :null=>false, :key=>[:id]
      foreign_key :role_id, :role, :type=>String, :size=>20, :null=>false, :key=>[:id]
      foreign_key :service_id, :service, :type=>String, :size=>8, :fixed=>true, :null=>false, :key=>[:id]
      String :condition, :size=>45, :null=>false
      foreign_key :parent_service_id, :service, :type=>String, :size=>8, :fixed=>true, :null=>false, :key=>[:id]
      
      primary_key [:activite_id, :role_id, :service_id, :parent_service_id]
      
      index [:role_id], :name=>:fk_activite_role_role1
      index [:service_id], :name=>:fk_activite_role_service1
      index [:parent_service_id], :name=>:fk_activite_role_service2
      index [:activite_id], :name=>:fk_role_has_service_has_activite_activite1
    end
    
    create_table(:application_key, :ignore_index_errors=>true) do
      foreign_key :application_id, :application, :type=>String, :size=>8, :fixed=>true, :null=>false, :key=>[:id]
      String :application_key, :size=>255, :null=>false
      String :application_secret, :size=>45, :null=>false
      DateTime :created_at, :null=>false
      Integer :validity_duration, :null=>false
      
      primary_key [:application_id]
      
      index [:application_id], :name=>:fk_application_key_application1
    end
    
    create_table(:email, :ignore_index_errors=>true) do
      primary_key :id
      String :adresse, :size=>255, :null=>false
      TrueClass :principal, :default=>false, :null=>false
      TrueClass :valide, :default=>false, :null=>false
      TrueClass :academique, :default=>false, :null=>false
      foreign_key :user_id, :user, :null=>false, :key=>[:id]
      
      index [:user_id], :name=>:fk_email_user1
    end
    
    create_table(:etablissement, :ignore_index_errors=>true) do
      primary_key :id
      String :code_uai, :size=>8, :fixed=>true
      String :nom, :size=>255
      String :siren, :size=>45
      String :adresse, :size=>255
      String :code_postal, :size=>6, :fixed=>true
      String :ville, :size=>255
      String :telephone, :size=>32
      String :fax, :size=>32
      Float :longitude
      Float :latitude
      Date :date_last_maj_aaf
      String :nom_passerelle, :size=>255
      String :ip_pub_passerelle, :size=>45
      foreign_key :type_etablissement_id, :type_etablissement, :null=>false, :key=>[:id]
      String :alimentation_state, :default=>"Non alimenté", :size=>45, :null=>false
      Date :alimentation_date
      TrueClass :data_received, :default=>false, :null=>false
      String :site_url, :size=>255
      String :logo, :size=>45
      Date :last_alimentation
      TrueClass :activate_alimentation
      String :ip_prive, :size=>45
      String :id_marquage_ministere, :size=>45
      String :url_blog, :size=>512
      Date :date_connexion_annuaire_ent
      
      index [:type_etablissement_id], :name=>:fk_etablissement_type_etablissement1
    end
    
    create_table(:param_application, :ignore_index_errors=>true) do
      primary_key :id
      String :code, :size=>45, :null=>false
      TrueClass :preference, :null=>false
      TrueClass :visible, :default=>true, :null=>false
      String :libelle, :size=>255
      String :description, :size=>1024
      String :valeur_defaut, :size=>2000
      String :autres_valeurs, :size=>2000
      foreign_key :application_id, :application, :type=>String, :size=>8, :fixed=>true, :null=>false, :key=>[:id]
      foreign_key :type_param_id, :type_param, :type=>String, :size=>8, :fixed=>true, :null=>false, :key=>[:id]
      
      index [:application_id], :name=>:fk_param_application_application1
      index [:type_param_id], :name=>:fk_param_application_type_param1
    end
    
    create_table(:profil_national, :ignore_index_errors=>true) do
      String :id, :size=>8, :fixed=>true, :null=>false
      String :description, :size=>100
      String :code_national, :size=>45
      foreign_key :role_id, :role, :type=>String, :size=>20, :key=>[:id]
      
      primary_key [:id]
      
      index [:role_id], :name=>:fk_profil_role1
    end
    
    create_table(:regroupement_libre, :ignore_index_errors=>true) do
      primary_key :id
      Date :created_at
      foreign_key :created_by, :user, :null=>false, :key=>[:id]
      String :libelle, :size=>45
      
      index [:created_by], :name=>:fk_regroupement_libre_user1
    end
    
    create_table(:relation_eleve, :ignore_index_errors=>true) do
      foreign_key :user_id, :user, :null=>false, :key=>[:id]
      foreign_key :eleve_id, :user, :null=>false, :key=>[:id]
      foreign_key :type_relation_eleve_id, :type_relation_eleve, :null=>false, :key=>[:id]
      TrueClass :resp_financier, :default=>false
      TrueClass :resp_legal, :default=>false
      TrueClass :contact, :default=>false
      TrueClass :paiement, :default=>false
      
      primary_key [:user_id, :eleve_id, :type_relation_eleve_id]
      
      index [:type_relation_eleve_id], :name=>:fk_relation_eleve_type_relation_eleve1
      index [:eleve_id], :name=>:fk_user_has_user_user1
      index [:user_id], :name=>:fk_user_has_user_user2
    end
    
    create_table(:ressource, :ignore_index_errors=>true) do
      String :id, :size=>255, :null=>false
      foreign_key :service_id, :service, :type=>String, :size=>8, :fixed=>true, :null=>false, :key=>[:id]
      
      primary_key [:id, :service_id]
      
      index [:service_id], :name=>:fk_ressource_service1
    end
    
    create_table(:telephone, :ignore_index_errors=>true) do
      primary_key :id
      String :numero, :size=>32, :fixed=>true, :null=>false
      foreign_key :user_id, :user, :null=>false, :key=>[:id]
      foreign_key :type_telephone_id, :type_telephone, :type=>String, :size=>8, :fixed=>true, :null=>false, :key=>[:id]
      
      index [:type_telephone_id], :name=>:fk_telephone_type_telephone1
      index [:user_id], :name=>:fk_telephone_user1
    end
    
    create_table(:application_etablissement, :ignore_index_errors=>true) do
      foreign_key :application_id, :application, :type=>String, :size=>8, :fixed=>true, :null=>false, :key=>[:id]
      foreign_key :etablissement_id, :etablissement, :null=>false, :key=>[:id]
      TrueClass :active, :default=>true
      
      primary_key [:application_id, :etablissement_id]
      
      index [:application_id], :name=>:fk_application_has_etablissement_application1
      index [:etablissement_id], :name=>:fk_application_has_etablissement_etablissement1
    end
    
    create_table(:membre_regroupement_libre, :ignore_index_errors=>true) do
      foreign_key :user_id, :user, :null=>false, :key=>[:id]
      foreign_key :regroupement_libre_id, :regroupement_libre, :null=>false, :key=>[:id]
      Date :joined_at
      
      primary_key [:user_id, :regroupement_libre_id]
      
      index [:regroupement_libre_id], :name=>:fk_user_has_regroupement_libre_regroupement_libre1
      index [:user_id], :name=>:fk_user_has_regroupement_libre_user1
    end
    
    create_table(:param_etablissement, :ignore_index_errors=>true) do
      foreign_key :etablissement_id, :etablissement, :null=>false, :key=>[:id]
      foreign_key :param_application_id, :param_application, :null=>false, :key=>[:id]
      String :valeur, :size=>2000
      
      primary_key [:etablissement_id, :param_application_id]
      
      index [:etablissement_id], :name=>:fk_param_application_has_etablissement_etablissement1
      index [:param_application_id], :name=>:fk_param_etablissement_param_application1
    end
    
    create_table(:param_user, :ignore_index_errors=>true) do
      foreign_key :user_id, :user, :null=>false, :key=>[:id]
      foreign_key :param_application_id, :param_application, :null=>false, :key=>[:id]
      String :valeur, :size=>2000
      
      primary_key [:user_id, :param_application_id]
      
      index [:user_id], :name=>:fk_param_application_has_user_user1
      index [:param_application_id], :name=>:fk_param_user_param_application1
    end
    
    create_table(:profil_user, :ignore_index_errors=>true) do
      foreign_key :profil_id, :profil_national, :type=>String, :size=>8, :fixed=>true, :null=>false, :key=>[:id]
      foreign_key :user_id, :user, :null=>false, :key=>[:id]
      foreign_key :etablissement_id, :etablissement, :null=>false, :key=>[:id]
      TrueClass :bloque
      TrueClass :actif
      
      primary_key [:profil_id, :user_id, :etablissement_id]
      
      index [:user_id], :name=>:fk_profil_has_user_user1
      index [:etablissement_id], :name=>:fk_profil_user_etablissement1
      index [:profil_id], :name=>:fk_profil_user_profil1
    end
    
    create_table(:regroupement, :ignore_index_errors=>true) do
      primary_key :id
      String :libelle, :size=>45
      String :description, :text=>true
      Date :date_last_maj_aaf
      String :libelle_aaf, :size=>8, :fixed=>true
      foreign_key :type_regroupement_id, :type_regroupement, :type=>String, :size=>8, :fixed=>true, :null=>false, :key=>[:id]
      foreign_key :code_mef_aaf, :niveau, :type=>String, :size=>20, :key=>[:ent_mef_jointure]
      foreign_key :etablissement_id, :etablissement, :null=>false, :key=>[:id]
      DateTime :date_creation, :default=>Sequel::CURRENT_TIMESTAMP, :null=>false
      String :url_blog, :size=>512
      
      index [:etablissement_id], :name=>:fk_regroupement_etablissement1
      index [:code_mef_aaf], :name=>:fk_regroupement_niveau1
      index [:type_regroupement_id], :name=>:fk_regroupement_type_regroupement1
    end
    
    create_table(:role_user, :ignore_index_errors=>true) do
      foreign_key :user_id, :user, :null=>false, :key=>[:id]
      foreign_key :role_id, :role, :type=>String, :size=>20, :null=>false, :key=>[:id]
      TrueClass :bloque, :default=>false, :null=>false
      foreign_key :etablissement_id, :etablissement, :null=>false, :key=>[:id]
      
      primary_key [:user_id, :role_id, :etablissement_id]
      
      index [:etablissement_id], :name=>:fk_role_user_etablissement1
      index [:role_id], :name=>:fk_role_user_role1
      index [:user_id], :name=>:fk_role_user_user1
    end
    
    create_table(:destinataires, :ignore_index_errors=>true) do
      foreign_key :regroupement_id, :regroupement, :null=>false, :key=>[:id]
      foreign_key :publipostage_id, :publipostage, :null=>false, :key=>[:id]
      
      primary_key [:regroupement_id, :publipostage_id]
      
      index [:publipostage_id], :name=>:fk_regroupement_has_publipostage_publipostage1
      index [:regroupement_id], :name=>:fk_regroupement_has_publipostage_regroupement1
    end
    
    create_table(:eleve_dans_regroupement, :ignore_index_errors=>true) do
      foreign_key :user_id, :user, :null=>false, :key=>[:id]
      foreign_key :regroupement_id, :regroupement, :null=>false, :key=>[:id]
      
      primary_key [:user_id, :regroupement_id]
      
      index [:regroupement_id], :name=>:fk_user_has_regroupement_regroupement2
      index [:user_id], :name=>:fk_user_has_regroupement_user2
    end
    
    create_table(:enseigne_dans_regroupement, :ignore_index_errors=>true) do
      foreign_key :user_id, :user, :null=>false, :key=>[:id]
      foreign_key :regroupement_id, :regroupement, :null=>false, :key=>[:id]
      foreign_key :matiere_enseignee_id, :matiere_enseignee, :type=>String, :size=>10, :null=>false, :key=>[:id]
      String :prof_principal, :default=>"N", :size=>45, :null=>false
      
      primary_key [:user_id, :regroupement_id, :matiere_enseignee_id]
      
      index [:matiere_enseignee_id], :name=>:fk_enseigne_regroupement_matiere_enseignee1
      index [:regroupement_id], :name=>:fk_user_has_regroupement_regroupement1
      index [:user_id], :name=>:fk_user_has_regroupement_user1
    end
    
    create_table(:profil_user_fonction, :ignore_index_errors=>true) do
      String :profil_id, :size=>8, :fixed=>true, :null=>false
      Integer :user_id, :null=>false
      Integer :etablissement_id, :null=>false
      foreign_key :fonction_id, :fonction, :null=>false, :key=>[:id]
      
      primary_key [:profil_id, :user_id, :etablissement_id, :fonction_id]
      foreign_key [:profil_id, :user_id, :etablissement_id], :profil_user, :name=>:fk_profil_user_has_fonction_profil_user1, :key=>[:profil_id, :user_id, :etablissement_id]
      
      index [:fonction_id], :name=>:fk_profil_user_fonction_fonction1
      index [:profil_id, :user_id, :etablissement_id], :name=>:fk_profil_user_has_fonction_profil_user1
    end
  end
end

# Adding Foreign Keys 

Sequel.migration do
  change do
    alter_table(:activite_role) do
      add_foreign_key [:activite_id], :activite, :name=>:fk_role_has_service_has_activite_activite1, :key=>[:id]
      add_foreign_key [:parent_service_id], :service, :name=>:fk_activite_role_service2, :key=>[:id]
      add_foreign_key [:role_id], :role, :name=>:fk_activite_role_role1, :key=>[:id]
      add_foreign_key [:service_id], :service, :name=>:fk_activite_role_service1, :key=>[:id]
    end
    
    alter_table(:application_etablissement) do
      add_foreign_key [:application_id], :application, :name=>:fk_application_has_etablissement_application1, :key=>[:id]
      add_foreign_key [:etablissement_id], :etablissement, :name=>:fk_application_has_etablissement_etablissement1, :key=>[:id]
    end
    
    alter_table(:application_key) do
      add_foreign_key [:application_id], :application, :name=>:fk_application_key_application1, :key=>[:id]
    end
    
    alter_table(:destinataires) do
      add_foreign_key [:publipostage_id], :publipostage, :name=>:fk_regroupement_has_publipostage_publipostage1, :key=>[:id]
      add_foreign_key [:regroupement_id], :regroupement, :name=>:fk_regroupement_has_publipostage_regroupement1, :key=>[:id]
    end
    
    alter_table(:eleve_dans_regroupement) do
      add_foreign_key [:regroupement_id], :regroupement, :name=>:fk_user_has_regroupement_regroupement2, :key=>[:id]
      add_foreign_key [:user_id], :user, :name=>:fk_user_has_regroupement_user2, :key=>[:id]
    end
    
    alter_table(:email) do
      add_foreign_key [:user_id], :user, :name=>:fk_email_user1, :key=>[:id]
    end
    
    alter_table(:enseigne_dans_regroupement) do
      add_foreign_key [:matiere_enseignee_id], :matiere_enseignee, :name=>:fk_enseigne_regroupement_matiere_enseignee1, :key=>[:id]
      add_foreign_key [:regroupement_id], :regroupement, :name=>:fk_user_has_regroupement_regroupement1, :key=>[:id]
      add_foreign_key [:user_id], :user, :name=>:fk_user_has_regroupement_user1, :key=>[:id]
    end
    
    alter_table(:etablissement) do
      add_foreign_key [:type_etablissement_id], :type_etablissement, :name=>:fk_etablissement_type_etablissement1, :key=>[:id]
    end
    
    alter_table(:membre_regroupement_libre) do
      add_foreign_key [:regroupement_libre_id], :regroupement_libre, :name=>:fk_user_has_regroupement_libre_regroupement_libre1, :key=>[:id]
      add_foreign_key [:user_id], :user, :name=>:fk_user_has_regroupement_libre_user1, :key=>[:id]
    end
    
    alter_table(:param_application) do
      add_foreign_key [:application_id], :application, :name=>:fk_param_application_application1, :key=>[:id]
      add_foreign_key [:type_param_id], :type_param, :name=>:fk_param_application_type_param1, :key=>[:id]
    end
    
    alter_table(:param_etablissement) do
      add_foreign_key [:etablissement_id], :etablissement, :name=>:fk_param_application_has_etablissement_etablissement1, :key=>[:id]
      add_foreign_key [:param_application_id], :param_application, :name=>:fk_param_etablissement_param_application1, :key=>[:id]
    end
    
    alter_table(:param_user) do
      add_foreign_key [:param_application_id], :param_application, :name=>:fk_param_user_param_application1, :key=>[:id]
      add_foreign_key [:user_id], :user, :name=>:fk_param_application_has_user_user1, :key=>[:id]
    end
    
    alter_table(:profil_national) do
      add_foreign_key [:role_id], :role, :name=>:fk_profil_role1, :key=>[:id]
    end
    
    alter_table(:profil_user) do
      add_foreign_key [:etablissement_id], :etablissement, :name=>:fk_profil_user_etablissement1, :key=>[:id]
      add_foreign_key [:profil_id], :profil_national, :name=>:fk_profil_user_profil1, :key=>[:id]
      add_foreign_key [:user_id], :user, :name=>:fk_profil_has_user_user1, :key=>[:id]
    end
    
    alter_table(:profil_user_fonction) do
      add_foreign_key [:fonction_id], :fonction, :name=>:fk_profil_user_fonction_fonction1, :key=>[:id]
      add_foreign_key [:profil_id, :user_id, :etablissement_id], :profil_user, :name=>:fk_profil_user_has_fonction_profil_user1, :key=>[:profil_id, :user_id, :etablissement_id]
    end
    
    alter_table(:regroupement) do
      add_foreign_key [:code_mef_aaf], :niveau, :name=>:fk_regroupement_niveau1, :key=>[:ent_mef_jointure]
      add_foreign_key [:etablissement_id], :etablissement, :name=>:fk_regroupement_etablissement1, :key=>[:id]
      add_foreign_key [:type_regroupement_id], :type_regroupement, :name=>:fk_regroupement_type_regroupement1, :key=>[:id]
    end
    
    alter_table(:regroupement_libre) do
      add_foreign_key [:created_by], :user, :name=>:fk_regroupement_libre_user1, :key=>[:id]
    end
    
    alter_table(:relation_eleve) do
      add_foreign_key [:eleve_id], :user, :name=>:fk_user_has_user_user1, :key=>[:id]
      add_foreign_key [:type_relation_eleve_id], :type_relation_eleve, :name=>:fk_relation_eleve_type_relation_eleve1, :key=>[:id]
      add_foreign_key [:user_id], :user, :name=>:fk_user_has_user_user2, :key=>[:id]
    end
    
    alter_table(:ressource) do
      add_foreign_key [:service_id], :service, :name=>:fk_ressource_service1, :key=>[:id]
    end
    
    alter_table(:role_user) do
      add_foreign_key [:etablissement_id], :etablissement, :name=>:fk_role_user_etablissement1, :key=>[:id]
      add_foreign_key [:role_id], :role, :name=>:fk_role_user_role1, :key=>[:id]
      add_foreign_key [:user_id], :user, :name=>:fk_role_has_user_user1, :key=>[:id]
    end
    
    alter_table(:telephone) do
      add_foreign_key [:type_telephone_id], :type_telephone, :name=>:fk_telephone_type_telephone1, :key=>[:id]
      add_foreign_key [:user_id], :user, :name=>:fk_telephone_user1, :key=>[:id]
    end
  end
end
