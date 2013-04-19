#coding: utf-8
#
# model for 'ressource' table
# generated 2012-10-23 17:29:17 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | varchar(255)        | false    | PRI      |            | 
# service_id                    | char(8)             | false    | PRI      |            | 
# parent_service_id             | char(8)             | false    | MUL      |            | 
# parent_id                     | varchar(255)        | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Ressource < Sequel::Model(:ressource)

  class NoClassError < StandardError
  end

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer
  
  unrestrict_primary_key()

  # Referential integrity
  many_to_one :service
  # Todo : make it work and add children
  #many_to_one :parent, :key=>[:parent_service_id, :parent_id], :class => self
  # Attention l'ordre est important
  one_to_many :role_user, :key => [:ressource_id, :ressource_service_id]

  def self.laclasse
    self[:service_id => SRV_LACLASSE]
  end

  # Not nullable cols and unicity validation
  def validate
    super
  end

  def before_destroy
    # Avant suppression, une ressource doit s'assurer de supprimer tous ses enfants
    #self.destroy_children()

    # On supprime tous les RoleUser liés à cette Ressource
    # Merci aux méthodes rajoutées par Sequel
    #role_user_dataset.destroy()
    super
  end

  # A la destruction d'une ressource, il faut supprimer ses ressources enfants
  def destroy_children()
    # self.children.each do |c|
    #   class_const = Service.class_map[c.service_id]
    #   raise NoClassError.new("Pas de classe rattachée au service=#{c.service_id}") if class_const.nil?
    #   child = class_const[c.id]
    #   child.destroy()
    # end
  end

  # Renvois toutes les ressources qui ont comme parent la ressource en cours
  def children()
    #Ressource.filter(:parent_id => self.id, :parent_service_id => self.service_id).all
  end

  def parent()
    #self.parent_id ? Ressource[:id => self.parent_id, :service_id => self.parent_service_id] : nil
  end

  # belongs_to function returns true if actual ressource belongs to parent_ressource
  def belongs_to(ressource)
    belongs_to = false

    if ressource.nil?
      belongs_to = false 
    
    # a ressource belongs to itself
    elsif ressource == self
      belongs_to = true   

    # all ressources belongs to root (Laclasse)
    elsif ressource == Ressource.laclasse 
      belongs_to = true
    
    # ressource user belongs to an etablissement and/or regroupement  
    elsif self[:service_id] == "USER"
      case ressource.service_id
        when "ETAB"
          belongs_to = (ProfilUser.filter(:user_id => self.id.to_i, :etablissement_id => ressource.id.to_i).count > 0)
        when "CLASSE"
          
          # enseingant 
          belongs_to = (EnseigneDansRegroupement.filter(:user_id => self.id.to_i, :regroupement_id => ressource.id.to_i).count > 0)
          # eleve  
          belongs_to ||= (EleveDansRegroupement.filter(:user_id => self.id.to_i, :regroupement_id => ressource.id.to_i).count > 0) 
          # parent_eleve belongs_to the class of his(her) child
          user = User[:id => self.id.to_i]
            user.enfants.each do |enfant|
              belongs_to ||= (EleveDansRegroupement.filter(:user_id => enfant.id, :regroupement_id => ressource.id.to_i).count > 0) 
            end  
        when "GROUPE"
          #enseignant
          belongs_to = (EnseigneDansRegroupement.filter(:user_id => self.id.to_i, :regroupement_id => ressource.id.to_i).count > 0)

          #eleve
          belongs_to ||= (EleveDansRegroupement.filter(:user_id => self.id.to_i, :regroupement_id => ressource.id.to_i).count > 0)

          # parent_eleve belongs_to the group of his(her) child
          user = User[:id => self.id.to_i]
            user.enfants.each do |enfant|
              belongs_to ||= (EleveDansRegroupement.filter(:user_id => enfant.id, :regroupement_id => ressource.id.to_i).count > 0) 
            end    
        else 
          belongs_to = false  
      end
    
    # ressource regroupement belongs to an etablissement
    elsif self[:service_id] == "CLASSE" || self[:service_id] == "GROUPE"    
      if ressource.service_id == "ETAB" && Regroupement[:id => self.id.to_i, :etablissement_id => ressource.id.to_i]
        belongs_to = true 
      end
    
    # ressource application belongs to an etablissement
    elsif self[:service_id] == "APPLICATION"
      if ressource.service_id == "ETAB" && !ApplicationEtablissement[:application_id => self.id, :etablissement_id => ressource.id.to_i].nil?
        belongs_to = true 
      end
    
    # ressource parameter may belongs to a user or etablissment or application 
    elsif self[:service_id] == "PARAM"
      if ressource.service_id == "ETAB" && !ParamEtablissement[:param_application_id => self.id.to_i, :etablissement_id => ressource.id.to_i].nil?
        belongs_to = true
      elsif ressource.service_id == "USER" && !ParamUser[:param_application_id => self.id.to_i, :user_id => ressource.id.to_i].nil?
        belongs_to = true 

      elsif ressource.service_id == "APPLICATION" && !ParamApplication[:id => self.id.to_i, :application_id => ressource.id].nil?
        belongs_to = true  
      end
    # TODO: ressource Role
    else 
      belongs_to = false 
    end
    #puts belongs_to
    belongs_to   
  end 
end
