module API
  module Entities
    class User < Grape::Entity
      #root 'users', 'user'
      expose :id, :id_sconet, :login, :nom, :prenom, :sexe
      expose(:full_name) {|user,options| user.full_name}
      expose :profil_user, :as => :profils
      expose :email, :as => :adresse_emails
      # etablissement + rights + profils
      expose(:etablissements) do |user,options|
        user.etablissements.map do |etab| 
           {:id => etab.id, :nom =>  etab.nom, :profils => etab.profil_user_dataset.filter(:user_id => user.id), :rights => user.rights(etab.ressource)}
        end
      end
      expose(:preferences) do |user,options|
        ParamApplication.filter(:preference => true).map do |preference|
          if param_user = ParamUser[:user_id => user.id, :param_application_id => preference.id]
            {:code => preference.code, :valeur => param_user.valeur}
          else
            {:code => preference.code, :valeur => preference.valeur_defaut}
          end 
        end 
      end 
      expose(:classes) do |user,options|
        user.classes.map do |classe|
          {:id => classe.id, :libelle  => classe.libelle, :rights => user.rights(classe.ressource)}
        end 
      end 
      expose :telephone, :as => :telephones
      expose(:groupes_eleves) do |user,options|
        user.groupes_eleves do |groupe|
          {:id => groupe.id, :libelle  => groupe.libelle, :rights => user.rights(groupe.ressource)}
        end 
      end 
      expose(:groupes_libres) do |user,options|
        user.groupes_libres do |groupe|
          {:id => groupe.id, :libelle  => groupe.libelle, :rights => user.rights(groupe.ressource)}
        end
      end 
    end
  end 
    
end