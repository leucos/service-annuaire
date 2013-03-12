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
      data.each do |matiere|
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
          data = JSON.parse(@data)
          modify_or_create_etablissement(data)
        
        when "CLASSES"
          puts "Classes"
          data = JSON.parse(@data)
          modify_or_create_regroupement(data)
          
        
        when "GROUPES"
          puts "groupes"
          data = JSON.parse(@data)
          modify_or_create_regroupement(data)
        
        when "COMPTES"
          puts "Compte: profile #{@profil}"
          data = JSON.parse(@data)
          modify_or_create_user(data)

        when "RATTACHEMENTS"
          puts "Rattachement: #{@profil}"
        
        when "DETACHEMENTS" 
          puts "DETACHEMENTS"

          

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
      
      # received data example 
      # {"id":"4813","code_uai":"0690078K","siren":"19690078100010","type_structure":"COLLEGE",
      #  "contrat":"PU","nom":"CLG-VAL D'ARGENT","adresse":"9 RUE DES PRAIRIES",
      #  "code_postal":"69610","ville":"STE FOY L ARGENTIERE","telephone":"+33 4 74 72 26 00",
      #  "fax":"+33 4 74 72 26 03","date_last_maj_aaf":"2013-03-12"}
      begin
        if data.length > 1
          puts "Error :too many structures are received" 
        end  
        structure = data[0]  # structure <> etablissement
        
        found_one = false
        
        # search etablissement for corresponding records
        record = Etablissement[:id => structure["id"], :code_uai => structure["code_uai"]]
        if record.nil? 
          found_one = false
        else 
          found_one = true 
        end
        
        # TODO : ask Pgl for cases
        if found_one && @type_import == "Complet"
          
          # modify
          puts "structure: #{structure['code_uai']} will be modifyed"
          record[:siren] = structure["siren"]
          record[:nom] = structure["nom"]
          record[:adresse] = structure["adresse"]
          record[:code_postal] = structure["code_postal"]
          record[:ville] = structure["ville"]
          record[:telephone] = structure["telephone"]
          record[:fax] = structure["fax"]
          record[:date_last_maj_aaf] = structure["date_last_maj_aaf"]
          
          type_etab = {:type_struct_aaf => structure["type_structure"], :type_contrat => structure["contrat"]}
          type_etab = TypeEtablissement.find_or_create(type_etab)
          record[:type_etablissement_id] = type_etab.id
          record.save
        
        elsif !found_one && @type_import == "Complet"
          # create
          puts "structure: #{structure['code_uai']} will be added"
          type_etab = {:type_struct_aaf => structure["type_structure"], :type_contrat => structure["contrat"]}
          type_etab = TypeEtablissement.find_or_create(type_etab)

          Etablissement.insert({:id => structure["id"], :code_uai => structure["code_uai"], :siren => structure["siren"],
            :nom => structure["nom"], :adresse => structure["adresse"], :code_postal => structure["code_postal"],
            :ville => structure["ville"],:telephone => structure["telephone"],:fax => structure["fax"], :date_last_maj_aaf => structure["date_last_maj_aaf"],
            :type_etablissement_id => type_etab.id})   
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
      #{"profil"=>"ELEVE", "id_sconet"=>"1035780", "id_jointure_aaf"=>"2414273", 
      # "nom"=>"AISSOU", "prenom"=>"Yanis", "date_naissance"=>"15/08/2001", "sexe"=>"M", "date_last_maj_aaf"=>"2013-02-28"}
      # we must capture errors in order to treat all eleves
      data.each do |eleve| 
        begin 
          found_one = false
          record = User[:id_jointure_aaf => eleve["id_jointure_aaf"]]
          # search Users for corresponding records
          if record.nil? 
            found_one = false
          else 
            found_one = true 
          end

          # Treate User
          if found_one && @type_import == "Complet"
            puts "update eleve #{eleve['id_jointure_aaf']}"
            # update where id_jointure_aaf = eleve["id_jointure_aaf"] with new hash
            record[:id_sconet] = eleve["id_sconet"]
            record[:nom] = eleve["nom"] 
            record[:prenom] = eleve["prenom"]
            record[:date_naissance] = eleve["date_naissance"]
            record[:sexe] = eleve["sexe"]

            record.save

            # add profil to user if not added
            profil_id = 'ELV'
            etablissement_id = Etablissement[:code_uai => @uai].id
            record.add_profil(etablissement_id, profil_id)
            
             
            # attach user to etablissment
            # add telphone, add email  
          elsif !found_one && @type_import == "Complet"
            puts "create user #{eleve['id_jointure_aaf']}"
            # find a suitable login for the user
            login = User.find_available_login(eleve["prenom"],eleve["nom"])
            # insert the hash into user table
            # TODO: generate default password algorithm instead of this
            password = login 
            user = User.create(:id_sconet => eleve["id_sconet"], :login => login, 
              :id_jointure_aaf => eleve["id_jointure_aaf"], :nom => eleve["nom"], :prenom => eleve["prenom"],
              :date_naissance => eleve["date_naissance"],:sexe => eleve["sexe"], :date_creation => eleve["date_last_maj_aaf"],
              :password => password)
            # add profil eleve to user
            profil_id = 'ELV'
            etablissement_id = Etablissement[:code_uai => @uai].id
            user.add_profil(etablissement_id, profil_id)
          
            # add emails 
            # add telephones
          else
            raise "error: delete not supported" 
          end
        rescue => e 
          puts e.message
        end     
      end # end each
    end  
    
    # -----------------------------------------------------------
    # synchronize  regroupement 
    # TODO: Modify received data to correspond to 
    # data table
    
    def modify_or_create_regroupement(data)
      puts "modify or create Regroupement is called" 
        # verify data length 
      if data.length == 0
        puts "Error :no regroupements to be treated" 
      end
      
      data.each do |regroupement|
        # search Regroupements table  for corresponding records
        # i do not know if libelle_aaf is unique ?!!
        begin
          etablissement = Etablissement[:code_uai => @uai]
          record = Regroupement[:libelle_aaf => regroupement["libelle_aaf"],:etablissement_id => etablissement.id]
          if record.nil? 
            found_one = false
          else 
            found_one = true 
          end
          
          # treatement of data
          # received class data example 
          # {"etablissement":"0690078K","libelle_aaf":"6A","type_regroupement_id":"CLS",
          # "code_mef_aaf":"1001000C11A","date_last_maj_aaf":"2013-03-12"}

          if found_one && regroupement["type_regroupement_id"] == "CLS"
            puts "Modify class  #{regroupement['libelle_aaf']}"
            #modify class 
            # update only code_mef_aaf and date_last_maj_aaf
            record[:code_mef_aaf] = regroupement["code_mef_aaf"]
            record[:date_last_maj_aaf] = regroupement["date_last_maj_aaf"] 
            record[:libelle] = regroupement["libelle"]
            record[:description] = regroupement["description"]
            record.save

          elsif !found_one && regroupement["type_regroupement_id"] == "CLS"
            puts "Add class #{regroupement['libelle_aaf']}"
            # create class 
            Regroupement.insert({:libelle_aaf => regroupement["libelle_aaf"],:etablissement_id => etablissement.id, 
              :code_mef_aaf => regroupement["code_mef_aaf"], :type_regroupement_id => regroupement["type_regroupement_id"], 
              :date_last_maj_aaf => regroupement["date_last_maj_aaf"]})


          # received groups data example 
          # {"etablissement":"0690078K","libelle_aaf":"3A GR AL","type_regroupement_id":"GRP",
          # "libelle":"3A Gr Alld2","date_last_maj_aaf":"2013-03-12"}  
          elsif found_one && regroupement["type_regroupement_id"] == "GRP"
            puts "Modify group #{regroupement['libelle_aaf']}"
            record[:code_mef_aaf] = regroupement["code_mef_aaf"]
            record[:date_last_maj_aaf] = regroupement["date_last_maj_aaf"] 
            record[:libelle] = regroupement["libelle"]
            record[:description] = regroupement["description"]
            record.save
            
          elsif !found_one && regroupement["type_regroupement_id"] == "GRP"
            puts "add group #{regroupement['libelle_aaf']}"
            Regroupement.insert({:libelle_aaf => regroupement["libelle_aaf"],:etablissement_id => etablissement.id, 
              :code_mef_aaf => regroupement["code_mef_aaf"], :type_regroupement_id => regroupement["type_regroupement_id"], 
              :date_last_maj_aaf => regroupement["date_last_maj_aaf"], :libelle => regroupement["libelle"] })
             
          elsif found_one && regroupement["type_regroupement_id"] == "LBR"
            puts "Modify group libre"
            # actually not feeded by the academy 
          elsif !found_one && regroupement["type_regroupement_id"] == "LBR"
            puts "add group libre"
            # actually not feeded by the academy  
          else 
            raise "received data has errors"
          end
        rescue => e 
          Laclasse::Log.error(e.message)
        end

      end #end loop  

    end # end modify_or_create_regroupement

  end
end