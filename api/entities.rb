module API
  module Entities
    class User < Grape::Entity
      #root 'users', 'user'
      expose :id, :id_sconet, :login, :nom, :prenom
      expose :profil_user, :as => :profils
      expose :email, :as => :adresse_emails
      expose(:name) {|user,options| [ user.prenom, user.nom ].join(' ')}
      #not too good etablissement
      expose(:etablissements) do |user,options|
        user.etablissements.map do |etab| 
           {:id => etab.id, :nom =>  etab.nom, :profils => etab.profil_user_dataset.filter(:user_id => user.id)}
        end
      end
      expose :classes
      expose :telephone, :as => :telephones
      #expose :preferences
      expose :groupes 
      expose()
    end
  end 
    
end