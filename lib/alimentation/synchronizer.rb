#!ruby
#coding: utf-8

# A class that takes alimentation data and feed the mysql database with it 
# 
module Alimentation
  
  class Synchronizer
    
    def initialize(type_import, uai, profil, type_data, data)
      @type_import = type_import 
      @uai = uai 
      @profil = profil
      @type_data = type_data
      @data = data  #type json
    end
    
    def sync()
       puts "sync() method is called"
       if @type_import == "Delta" 
        sync_delta()
       elsif @type_import =="Complet"
        sync_complet()
       else 
         raise "Alimentation type is not valide"   
       end
    end
    
    private
    
    def sync_delta()
      puts "sync_delta is called"
      # database should not be emptied
    end
    
    def sync_complet()
      puts "sync_complet is called"
      case @type_data
        when "STRUCTURES"
          puts "structure"
          data = JSON.parse(@data)
          modify_or_create_etablissement(data)
        when "COMPTES"
          puts "Compte: profile #{@profil}"
          modify_or_create_user(profil, data)
        when "CLASSES"
          modify_or_create_regroupement('CLS', data)
          puts "Class"
        when "GROUPES"
          modify_or_create_regroupement('GRP', data)
          puts "groupes"
        when "RATTACHEMENTS"
          puts "Rattachement: #{@profil}"
        when  "DETACHEMENTS" 
          puts "DETACHEMENTS" 
        else
          puts "I will raise an error "
        end 
      # database is not emptied
      # i think order is important
      # add data to the database;
    end
    
    def modify_or_create_etablissement(data)
      puts data.inspect
    end
    
    def modify_or_create_user(profil, data)
      
    end
    
    def modify_or_create_regroupement(groupe, data)
      
    end 
    
=begin   
    def clean_data(table, hash)
      # Hash représentant les changements a effectuer sur les données
      # Nécessaire car on ne peut pas supprimer ou rajouter des clés pendant un each
      to_change = {}
      columns = MODEL_MAP[table].columns()
      hash.each do |k, v|
        unless columns.include?(k)
          #todo : generer une erreur si la colonne n'existe pas
          #Ou que l'id est a nil
          new_column = "#{k}_id".to_sym()
          new_value = v[:id]
          if columns.include?(new_column) and !new_value.nil?
            to_change[k] = [new_column, new_value]
          end
        end
      end

      #Il faut absoluement garder le même hash (et non en recrééer un)
      #Car il est référencé dans les diff.
      to_change.each do |k, v|
        hash.delete(k)
        hash[v[0]] = v[1]
      end

      return hash
    end

    def create(table, hash)
      begin
        model = MODEL_MAP[table].create(hash)
        hash[:id] = model[:id]
      rescue => e
        puts "Non valid hash on table #{table} : #{hash}"
        puts "#{e.message}"
        #puts "#{e.backtrace}"
        #exit()
      end
    end

    def find_model(table, hash)
      model_class = MODEL_MAP[table]
      uid = {}
      #Primary_key peut renvoyer soit un tableau ou un seul élément
      id_name_list = model_class.primary_key
      if id_name_list.kind_of?(Array)
        #Construction du hash représentant l'id unique du model
        id_name_list.each do |id_name|
          uid[id_name] = hash[id_name]
        end
      else
        uid[id_name_list] = hash[id_name_list]
      end
      return model_class[uid]
    end

    def update(table, hash)
      model = find_model(table, hash)
      #todo : gérer l'erreur
      unless model.nil?
        begin
          model.update(hash)
        rescue => e
          puts "Non valid hash on table #{table} : #{hash}"
          puts "#{e.message}"
          puts "#{e.backtrace}"
          #exit()   
        end
      end
      
    end

    def delete(table, hash)
      model = find_model(table, hash)
      #todo : gérer l'erreur
      unless model.nil?
        model.destroy()
      end   
    end

    def sync_db(diff)
      #Important : se base sur le fait que les tables dans diff
      #commencent par user et regroupement car ces deux tables sont référencées
      #partout ailleurs donc lors des create, on a besoin de spécifier les id
      diff.each do |table, action_list|
        action_list.each do |action, hash_list|
          hash_list.each do |hash|
            if action == :update
              hash = hash[:updated]
            end
            #puts hash if table == :regroupement and hash[:user][:id_jointure_aaf] == "2072161"
            hash = clean_data(table, hash)
            #puts hash if table == :relation_eleve and hash[:user][:id_jointure_aaf] == "2072161"
            case action
            when :create
              create(table, hash)
            when :update
              update(table, hash)
            when :delete
              delete(table, hash)
            end
          end
        end
      end
    end
  
=end   
  end
end