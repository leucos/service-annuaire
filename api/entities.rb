module API
  module Entities
    class DetailedUser < Grape::Entity
      #root 'users', 'user'
      # TODO expose resource url instead of ids
      expose :id, :id_sconet, :login, :id_jointure_aaf,  :nom, :prenom, :sexe, :id_ent, :date_naissance, :adresse, :code_postal, :ville
      expose(:full_name) {|user,options| user.full_name} 
      expose(:profils) {|user,options| user.profil_user_display}
      expose(:default_password){|user,options| user.is_default_pass?}
      expose(:roles){|user,options| user.role_user_display}
      expose :email, :as => :emails
      # etablissement + rights + profils
      expose(:etablissements) do |user,options|
        user.etablissements.map do |etab| 
           {:id => etab[:id], :nom =>  etab[:nom], :profils => ProfilUser.filter(:user_id => user.id), :rights => user.rights(etab[:id])}
        end
      end
      # # expose(:preferences) do |user,options|
      # #   ParamApplication.filter(:preference => true).map do |preference|
      # #     if param_user = ParamUser[:user_id => user.id, :param_application_id => preference.id]
      # #       {:code => preference.code, :valeur => param_user.valeur}
      # #     else
      # #       {:code => preference.code, :valeur => preference.valeur_defaut}
      # #     end 
      # #   end 
      # # end 

      # Note: There is a problem here ( This code displays only eleve classes and groupes)
      expose(:classes) do |user,options|
        user.classes_display
      end 

      expose :telephone, :as => :telephones
      
      expose(:groupes_eleves) do |user,options|
        user.groupes_display
      end 

      expose(:groupes_libres) do |user,options|
        user.groupes_libres 
      end

      expose(:matieres_enseignees) do |user, options|
        user.matieres_enseignees
      end

      expose(:parents) do |user, options|
        user.parents
      end

      expose(:enfants) do |user, options|
        a = []
        user.enfants.each do |enfant|
           a.push({:enfant => enfant, :etablissements => user.etablissements, :classes => enfant.classes_display, 
            :groupes_eleves => enfant.groupes_display, :groupes_libres => enfant.groupes_libres})
        end
        a
      end
      expose(:relations_eleves) do |user,options|
        user.relations_eleves
      end

      expose(:relations_adultes) do |user, options|
        user.relations_adultes
      end
    end

    class SimpleUser < Grape::Entity
      #format_with :iso_timestamp{ |dt| dt.iso8601 }
      #root 'users', 'user'
      expose :id, :id_sconet, :id_jointure_aaf, :login, :nom, :prenom, :sexe, :id_ent, :date_naissance, :adresse, :code_postal, :ville
      expose(:full_name) {|user,options| user.full_name}
      expose(:profils) {|user,options| user.profil_user_display}
      expose :telephone, :as => :telephones
      expose :email, :as => :emails
=begin
      expose(:classes) do |user,options|
        user.classes_display
      end

      expose(:groupes_eleve) do |user, options|
        user.groupes_display
      end

      expose(:matieres_enseignees) do |user, options|
        user.matieres_enseignees
      end 
      expose(:groupes_libres) do |user,options|
        user.groupes_libres 
      end 
=end      
    end

    class SimpleEtablissement < Grape::Entity 
      expose :id, :code_uai, :siren, :nom, :adresse, :code_postal, :ville, :type_etablissement_id, :telephone, :fax
      expose :full_name, :alimentation_state, :alimentation_date, :data_received, :longitude, :latitude, :site_url , :logo, :activate_alimentation
    end

    class DetailedEtablissement < Grape::Entity
      expose :id, :code_uai, :nom, :adresse, :code_postal, :ville, :type_etablissement_id, :telephone, :fax, 
      :full_name, :alimentation_state, :alimentation_date, :data_received, :longitude, :latitude, :site_url , :logo
      expose :classes
      expose :groupes_eleves
      expose :groupes_libres
      expose(:personnel) do |etab, options|
        etab.personnel
      end  
      expose :contacts 
      expose :eleves
      expose :enseignants
      expose :parents
    end

    class SimpleRegroupement < Grape::Entity
      expose :id, :etablissement_id, :libelle, :libelle_aaf, :type_regroupement_id 
    end   

    class DetailedRegroupement < Grape::Entity
      expose :id, :etablissement_id, :libelle, :libelle_aaf, :type_regroupement_id
      expose(:profs) {|regroupement,options| regroupement.profs}
      expose(:eleves) {|regroupement,options| regroupement.eleves}
    end


    class SimpleGroupeLibre < Grape::Entity
      expose :id, :created_at, :created_by, :libelle
    end

    class DetailedGroupeLibre < Grape::Entity
      expose :id, :created_at, :created_by, :libelle
      expose(:membres){|regroupement,options| regroupement.membres}
      expose(:responsable){|regroupement,options| regroupement.responsable}
    end 
  end 
    
end