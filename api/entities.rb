module API
  module Entities
    class DetailedUser < Grape::Entity
      #root 'users', 'user'
      # TODO expose resource url instead of ids
      expose :id, :id_sconet, :login, :nom, :prenom, :sexe, :id_ent
      expose(:full_name) {|user,options| user.full_name} 
      expose(:profils) {|user,options| user.profil_user_display}
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
    end

    class SimpleUser < Grape::Entity
      #format_with :iso_timestamp{ |dt| dt.iso8601 }
      #root 'users', 'user'
      expose :id, :id_sconet, :login, :nom, :prenom, :sexe, :id_ent, :date_naissance, :adresse, :code_postal, :ville
      expose(:full_name) {|user,options| user.full_name}
      expose(:profils) {|user,options| user.profil_user_display}
      expose :telephone, :as => :telephones
      expose :email, :as => :emails
      #comment block
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
      expose :full_name, :alimentation_state, :alimentation_date, :data_received, :longitude, :latitude, :site_url , :logo
    end

    class DetailedEtablissement < Grape::Entity
      expose :id, :code_uai, :nom, :adresse, :code_postal, :ville, :type_etablissement_id, :telephone, :fax, 
      :full_name, :alimentation_state, :alimentation_date, :data_received, :longitude, :latitude, :site_url , :logo
      expose :classes 
      expose :groupes_eleves
      expose :groupes_libres
      expose(:personnel) do |etab, options|
        etab.personnel 
        #do |person| 
          #{:id => person.id, :full_name => person.full_name}
        #end
      end  
      expose :contacts 
    end

    class SimpleRegroupement < Grape::Entity
      expose :id, :etablissement_id, :libelle, :libelle_aaf, :type_regroupement_id 
    end   

    class DetailedRegroupement < Grape::Entity
      expose :id, :etablissement_id, :libelle, :libelle_aaf, :type_regroupement_id
      expose(:profs) {|regroupement,options| regroupement.profs}
      expose(:eleves) {|regroupement,options| regroupement.eleves}
    end 
  end 
    
end