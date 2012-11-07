module API
  module Entities
    class User < Grape::Entity
      #root 'users', 'user'
      expose :id, :id_sconet, :login, :nom, :prenom
      expose :email, :as => :adresse_emails
      expose(:name) {|user,options| [ user.prenom, user.nom ].join(' ')}
      expose :etablissements 
      expose :classes
      expose :telephone, :as => :telephones
      #expose :preferences
      expose :groupes 
    end
  end 
    
end