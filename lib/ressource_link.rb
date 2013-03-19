#coding: utf-8
module Sequel
  module Plugins
    # Plugin qui rajoute une relation one_to_one vers une ressource du type de la classe
    # avec son id et qui gère la création/suppression automatique de la ressource
    # Note : chaque classe pourra surcharger ces mécanisme pour 
    # par exemple changer le parent_id et parent_service_id
    # plugins 
    
    # A singleton method named apply, which takes a model, additional arguments, 
    # and an optional block. This is called the first time the plugin is loaded for this model 
    # (unless it was already loaded by an ancestor class), before including/extending any modules, 
    # with the arguments and block provided to the call to Model.plugin.
    
    # A module inside the plugin module named InstanceMethods, which will be included in the model class.

    # A module inside the plugin module named ClassMethods, which will extend the model class.

    # A module inside the plugin module named DatasetMethods, which will extend the model's dataset.

    #A singleton method named configure, which takes a model, additional arguments, and an optional block. This is called every time the Model.plugin method is called, after including/extending any modules.
    module RessourceLink
      class NoServiceError < StandardError
      end

      def self.apply(model, hash={})
        raise NoServiceError.new("service_id need for plugin ressource_data") if hash[:service_id].nil?
        # todo : ca serait bien de pouvoir rajouter une variable de classe
        service_id = hash[:service_id]
        Service.declare_service_class(service_id, model)

        model.one_to_one :ressource, :key => :id do |ds|
          ds.where(:service_id => service_id)
        end
      end
      module InstanceMethods
        def after_create
          puts "RessourceLink called for #{self.id}"
          # Je n'arrive pas a rajouter de variable de classe dynamiquement en ruby
          # Donc je vais rechercher le service ID à la mano
          service_id = Service.class_map.rassoc(self.class)[0]
          # Rajoute l'instance en tant que ressource enfant de laclasse 
          # Il pourra ensuite être mis en tant qu'enfant d'un établissement pour donnée le droit à l'admin d'établissement de le modifier/supprimer par exemple
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