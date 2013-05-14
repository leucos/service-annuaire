module API
  module Entities
    class DetailedUser < Grape::Entity
      #root 'users', 'user'
      # TODO expose resource url instead of ids
      expose :id, :id_sconet, :login, :nom, :prenom, :sexe, :id_ent
      expose(:full_name) {|user,options| user.full_name}
      expose :profil_user, :as => :profils
      expose :email, :as => :adresse_emails
      # etablissement + rights + profils
      expose(:etablissements) do |user,options|
        user.etablissements.map do |etab| 
           {:id => etab[:id], :nom =>  etab[:nom], :profils => ProfilUser.filter(:user_id => user.id), :rights => user.rights(etab[:id])}
        end
      end
      # expose(:preferences) do |user,options|
      #   ParamApplication.filter(:preference => true).map do |preference|
      #     if param_user = ParamUser[:user_id => user.id, :param_application_id => preference.id]
      #       {:code => preference.code, :valeur => param_user.valeur}
      #     else
      #       {:code => preference.code, :valeur => preference.valeur_defaut}
      #     end 
      #   end 
      # end 
      expose(:classes) do |user,options|
        user.classes_eleve.map do |classe|
          {:id => classe.id, :libelle  => classe.libelle, :rights => user.rights(classe.ressource)}
        end 
      end 
      expose :telephone, :as => :telephones
      expose(:groupes_eleves) do |user,options|
        user.groupes_eleve do |groupe|
          {:id => groupe.id, :libelle  => groupe.libelle, :rights => user.rights(groupe.ressource)}
        end 
      end 
      expose(:groupes_libres) do |user,options|
        user.groupes_libres do |groupe|
          {:id => groupe.id, :libelle  => groupe.libelle, :rights => user.rights(groupe.ressource)}
        end
      end 
    end

    class SimpleUser < Grape::Entity
      #root 'users', 'user'
      expose :id, :id_sconet, :login, :nom, :prenom, :sexe, :id_ent
      expose(:full_name) {|user,options| user.full_name}
      expose :profil_user, :as => :profils 
    end

    class SimpleEtablissement < Grape::Entity 
      expose :id, :code_uai, :nom, :adresse, :code_postal, :ville, :type_etablissement_id, :telephone, :fax
      expose :full_name
    end

    class DetailedEtablissement < Grape::Entity
      expose :id, :code_uai, :nom, :adresse, :code_postal, :ville, :type_etablissement_id, :telephone, :fax
      expose :full_name
      expose :classes 
      expose :groupes_eleves
      expose :groupes_libres
      expose(:personnel) do |etab, options|
        etab.personnel do |person|
          {:id => person.id, :full_name => person.full_name}
        end
      end  
      expose :contacts 
    end

  end 
    
end