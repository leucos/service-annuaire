#!ruby
#coding: utf-8

# A class that takes alimentation data and feed the mysql database with it 
# TODO: Error management
# TODO: Display execution Time 
module Alimentation
  
  class Synchronizer
    
    def initialize(type_import, uai, profil, type_data, data)
      @type_import = type_import 
      @uai = uai 
      @profil = profil
      @type_data = type_data
      @data = data  # must be transformed to type json , refactor code
      
      #if we want to store data temporarly in mongoDB
      #@db =DataBase.connect({:server => "localhost", :db => "mydb"})
    end
    
    #-----------------------------------------------------------#
    # data is validated before because of JSON.parse method
    # sync niveau ou mef educ nat
    def self.sync_mef(data) 
      puts "synchronize mef educ nationale"
      data.each do |mef_educ_nat|
        begin 
          record = Niveau[:ent_mef_jointure => mef_educ_nat["ENTMefJointure"]]
          if record.nil? # not found => add record 
            Niveau.insert(:ent_mef_jointure => mef_educ_nat["ENTMefJointure"], :mef_libelle => mef_educ_nat["ENTLibelleMef"],
              :ent_mef_rattach => mef_educ_nat["ENTMEFRattach"], :ent_mef_stat => mef_educ_nat["ENTMEFSTAT11"]) 
          else  # => modify record 
            record[:mef_libelle] = mef_educ_nat["ENTLibelleMef"]
            record[:ent_mef_rattach] = mef_educ_nat["ENTMEFRattach"]
            record[:ent_mef_stat] = mef_educ_nat["ENTMEFSTAT11"]
            record.save # update
          end
        rescue  => e 
          # change puts to Laclasse::Log.error
          puts "Error: #{e.message}"
        end  
      end # end data.each    
      puts "Mef synchronized successfully"
    end # end sync_mef


    #-----------------------------------------------------------#
    # sync matieres education nationale
    def self.sync_matieres(data)
      puts "synchronize matieres educ national"
      # received data 
      # {"code_men":"-","libelle":"ASSISTANT D'EDUCATION","description":"SANS OBJET"}
      data.each do |fonction|
        begin 
          record = MatiereEnseignee[:id => matiere["ENTMatJointure"]]
          if record.nil? # not found => add matiere 
            MatiereEnseignee.insert(:id => matiere["ENTMatJointure"], :libelle_long => matiere["ENTLibelleMatiere"]) 
          else  # => modify record 
            record[:libelle_long] = matiere["ENTLibelleMatiere"]
            record.save # update
          end
        rescue  => e 
          # change puts to Laclasse::Log.error
          puts "Error: #{e.message}"
        end  
      end # end data.each    
      puts "Matieres synchronized successfully"  
    end

    #-----------------------------------------------------------#
    # sync fonction 
    def self.sync_fonction(data)
      puts "synchronize fonctions"
      # received data 
      # {"code_men":"-","libelle":"ASSISTANT D'EDUCATION","description":"SANS OBJET"}
      data.each do |fonction|
        begin 
          record = Fonction[:code_men => fonction["code_men"]]
          if record.nil? # not found => add matiere 
            Fonction.insert(:code_men => fonction["code_men"], :libelle => fonction["libelle"], 
              :description => fonction["description"]) 
          else  # => modify record 
            record[:libelle] = fonction["libelle"]
            record[:description] = fonction["description"] 
            record.save # update
          end
        rescue  => e 
          # change puts to Laclasse::Log.error
          puts "Error: #{e.message}"
        end  
      end # end data.each    
      puts "Fonctions synchronized successfully"  

    end

    #-----------------------------------------------------------# 
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
    
    # -----------------------------------------------------------
    # method responsable for synchronizing complet data
    # i think treatement order is important 
    def sync_complet()
      puts "sync_complet is called"
      case @type_data
        
        when "STRUCTURES"
          puts "structure"
          #TODO manque type_etablissement_id
          data = JSON.parse(@data)
          modify_or_create_etablissement(data)

        when "COMPTES"
          #puts "Compte: profile #{@profil}"
          #data = JSON.parse(@data)
          #modify_or_create_user(data)
        
        when "CLASSES"
          puts "Classes"
          #data = JSON.parse(@data)
          #modify_or_create_regroupement(data)
          
        
        when "GROUPES"
          puts "groupes"
          #data = JSON.parse(@data)
          #modify_or_create_regroupement(data)
          
        when "RATTACHEMENTS"
          puts "Rattachement: #{@profil}"
        
        when "DETACHEMENTS" 
          puts "DETACHEMENTS"

        when "MATIERES"
          puts "matiere"

        when "MEFEDUCNAT"
          puts "mef"

        else
          puts "I will raise an error "
        end 
    end
    
    # -----------------------------------------------------------
    # synchronize structure
    def modify_or_create_etablissement(data)
      puts "modify or create structure is called"
      # TODO: many structures or one structure is sent 
      # NOTE: i consider one structure is sent
      #puts "received data" 
      #puts data.inspect 
      begin
        if data.length > 1
          puts "Error :too many structures are received" 
        end  
        structure = data[0]  # structure <> etablissement
        # 1) TODO: rename key structure_jointure to id 
        structure.merge!({"id" => structure["structure_jointure"]})
        structure.reject! {| key, value | key =="structure_jointure"} 
        found_one = false
        
        # search etablissement for corresponding records
        if Etablissement[:id => structure["id"]].nil? == false 
          found_one = true
        elsif Etablissement[:id => structure["id"]].nil? == true
          found_one = false 
        end
        
        # TODO : ask Pgl for cases
        if found_one && @type_import == "Complet"
          puts "structure: #{structure['code_uai']} will be modifyed"
          Etablissement.where(:id => structure["id"]).update(structure)
        elsif !found_one && @type_import == "Complet"
          puts "structure: #{structure['code_uai']} will be added"
          Etablissement.insert(structure)
        else
          raise "not supported"  
        end    
       rescue => e
         Laclasse::Log.error(e.message) 
       end 
    end
    
    # -----------------------------------------------------------
    # syncronize user
    def modify_or_create_user(data)
      puts "modify or create user is called"

      # three cases 
        # eleves 
        # perseducnat
        # parent
      
      # modify_or_create_eleves(data)

      #Compte profil person educ nat
      #{"type_alim"=>"Complet", "profil"=>"PERSEDUCNAT", "id_jointure_aaf"=>"19797", "nom"=>"ANGONIN", 
      #"prenom"=>"FRANCOISE", "date_naissance"=>"13/09/1952", "sexe"=>"F", "mail"=>"Francoise.Angonin@ac-lyon.fr", 
      #"mail_academique"=>"Y", "date_last_maj_aaf"=>"2013-02-28"
      # modify_or_create_presons(data)

      #Compte profil parents
      #{"type_alim"=>"Complet", "profil"=>"PARENT", "id_jointure_aaf"=>"2028471", "nom"=>"AKCHOTE", "prenom"=>"Maria", 
      #"date_naissance"=>"", "sexe"=>"F", "adresse"=>"LE RAMPEAU", "code_postal"=>"69690", "ville"=>"BRULLIOLES", 
      #"tel_home"=>"+33 4 78 25 03 43", "tel_work"=>"", "mail"=>"", "date_last_maj_aaf"=>"2013-02-28"}
      
      # modify_or_create_parent(data)
      begin
        data = JSON.parse(@data)
        case @profil
          when "ELEVE"
            modify_or_create_eleves(data)
          when "PARENT"
            #modify_or_create_parents(data)
          when "PERSEDUCNAT"
            #modify_or_create_presons(data)
          else
            raise "profil not supported"
          end   
      rescue => e
        Laclasse::Log.error(e.message)
      end  
   
    end #end modify_or_create_user

    # -----------------------------------------------------------
    def modify_or_create_eleves(data)  
      # Example data:  
      #COMPTE profil eleve: 
      #{"type_alim"=>"Complet", "profil"=>"ELEVE", "id_sconet"=>"1035780", "id_jointure_aaf"=>"2414273", 
      # "nom"=>"AISSOU", "prenom"=>"Yanis", "date_naissance"=>"15/08/2001", "sexe"=>"M", "date_last_maj_aaf"=>"2013-02-28"}
      # we must capture errors in order to treat all eleves
      data.each do |eleve| 
        begin 
          found_one = false
          
          # search Users for corresponding records
          if User[:id_jointure_aaf => eleve["id_jointure_aaf"]].nil? == false 
            found_one = true
          elsif User[:id_jointure_aaf => eleve["id_jointure_aaf"]].nil? == true
            found_one = false 
          end

          # Treate User
          if found_one && @type_import == "Complet"
            # update user 
            # create a new hash with updated values 
            # update where id_jointure_aaf = eleve["id_jointure_aaf"] with new hash
            # add profil to user if not added 
            # attach user to etablissment
            # add telphone, add email  
          elsif !found_one && @type_import == "Complet"
            # create user
            # puts "create eleve"
            # find a suitable login for the user
            # create a hash with received values 
            # insert the hash into user table 
            # add profil to user 
            # add emails 
            # add telephones
          else
            raise "error: delete not supported" 
          end
        rescue => e 
          puts "continue to next user"
        end     
      end # end each
    end  
    
    # -----------------------------------------------------------
    # synchronize  regroupement 
    # TODO: Modify received data to correspond to 
    # data table
    def modify_or_create_regroupement(data)
      puts "modify or create Regroupement is called" 
      begin
        # verify data length 
        if data.length == 0
          puts "Error :no regroupements to be treated" 
        end
        
        data.each do |regroupement|
          # search Regroupements for corresponding records
          # i do not know if libelle_aaf is unique ?!!
          if Regroupement[:libelle => regroupement["libelle_aaf"]].nil? == false 
            found_one = true
          elsif Regroupement[:libelle => regroupement["libelle_aaf"]].nil? == false 
            found_one = false 
          end
          
          # treatement of data
          # TODO : modify the received json data to contain the fallowing elements
          # [libelle, code_mef?, data_last_maj_.., libelle-aaf, niveau or niveau_id(int), 
          # Etablissement_id, type_regroupement_id]
          
          if found_one && regroupement["type_regroupement_id"] == "CLS"
            puts "Modify class"
            #modify class 
            #Regroupement.where(:libelle => regroupement["libelle_aaf"]).update(regroupement)
          elsif !found_one && regroupement["type_regroupement_id"] == "CLS"
            puts "Add class"
            # create class 
            # Regroupement.create(regroupement)
          elsif found_one && regroupement["type_regroupement_id"] == "GRP"
            puts "Modify group"
            #Regroupement.where(:libelle => regroupement["libelle_aaf"]).update(regroupement)
          elsif !found_one && regroupement["type_regroupement_id"] == "GRP"
            puts "add group"
            #Regroupement.create(regroupement) 
          elsif found_one && regroupement["type_regroupement_id"] == "LBR"
            puts "Modify group libre"
            #Regroupement.where(:libelle => regroupement["libelle_aaf"]).update(regroupement)
          elsif !found_one && regroupement["type_regroupement_id"] == "LBR"
            puts "add group libre"
            #Regroupement.create(regroupement) 
          else 
            puts "data has errors"
          end
        end 
             
      rescue => e
        Laclasse::Log.error(e.message) 
      end

    end # end modify_or_create_regroupement

  end
end