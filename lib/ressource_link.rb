module Sequel
  module Plugins
    # Plugin qui rajoute une relation one_to_one vers une ressource du type de la classe
    # avec son id et qui gère la création/suppression automatique de la ressource
    # Note : chaque classe pourra surcharger ces mécanisme pour 
    # par exemple changer le parent_id et parent_service_id
    module RessourceLink
      class NoServiceError < StandardError
      end

      def self.apply(model, hash={})
        raise NoServiceError.new("service_id need for plugin ressource_data") if hash[:service_id].nil?
        # todo : ca serait bien de pouvoir rajouter une variable de classe
        service_id = hash[:service_id]
        Service.declare_service_class(service_id, model)

        # Retrieve Service ID from 
        model.one_to_one :ressource, :key => :id do |ds|
          ds.where(:service_id => service_id)
        end
      end
      module InstanceMethods
        def after_create
          # Je n'arrive pas a rajouter de variable de classe dynamiquement en ruby
          # Donc je vais rechercher le service ID à la mano
          service_id = Service.class_map.rassoc(self.class)[0]
          # Rajoute l'instance en tant que ressource enfant de laclasse 
          # Il pourra ensuite être mis en tant qu'enfant d'un établissement pour donnée le droit à l'admin d'établissement de le modifier/supprimer par exemple
          Ressource.unrestrict_primary_key()
          Ressource.create(:id => self.id, :service_id => service_id,
            :parent_id => Ressource[:service_id => SRV_LACLASSE].id, :parent_service_id => SRV_LACLASSE)
          super
        end

        def before_destroy
          # Supprimera toutes les ressources liées à cette instance
          self.ressource.destroy() if self.ressource
          super
        end
      end
    end
  end
end