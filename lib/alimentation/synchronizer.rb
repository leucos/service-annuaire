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
      Laclasse::Log.info("synchronize mef educ nationale")
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
          Laclasse::Log.error(e.message)
        end  
      end # end data.each    
      Laclasse::Log.info("Mef synchronized successfully")
    end # end sync_mef


    #-----------------------------------------------------------#
    # sync matieres education nationale
    def self.sync_matieres(data)
      Laclasse::Log.info("synchronize matieres educ national")
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
          Laclasse::Log.error(e.message)
        end  
      end # end data.each    
      Laclasse::Log.info(Matieres synchronized successfully)  
    end

    #-----------------------------------------------------------#
    # sync fonction 
    def self.sync_fonction(data)
      Laclasse::Log.info("synchronize fonctions")
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
          Laclasse::Log.error(e.message)
        end  
      end # end data.each    
      Laclasse::Log.info("Fonctions synchronized successfully")  

    end

    #-----------------------------------------------------------# 
    def sync()
      Laclasse::Log.info("sync() method is called")
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
      Laclasse::Log.info("sync_complet is called")
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
          data = JSON.parse(@data)
          modify_or_create_rattachement(data)
        
        when "DETACHEMENTS" 
          puts "DETACHEMENTS"  
          data = JSON.parse(@data)
          #puts data.first
          dettache_profil(data)

        when "FONCTIONS"
          puts "FONCTIONS"
          data = JSON.parse(@data)
          #puts data.first
          rattache_fonction_person(data)  

        else
          raise "data type is not valid"
        end 
    end
    
    # -----------------------------------------------------------
    # synchronize structure
    def modify_or_create_etablissement(data)
      Laclasse::Log.info("modify or create structure is called")
      # TODO: many structures or one structure is sent 
      # NOTE: i consider one structure is sent
      
      # received data example 
      # {"id":"4813","code_uai":"0690078K","siren":"19690078100010","type_structure":"COLLEGE",
      #  "contrat":"PU","nom":"CLG-VAL D'ARGENT","adresse":"9 RUE DES PRAIRIES",
      #  "code_postal":"69610","ville":"STE FOY L ARGENTIERE","telephone":"+33 4 74 72 26 00",
      #  "fax":"+33 4 74 72 26 03","date_last_maj_aaf":"2013-03-12"}
      begin
        if data.length > 1
          raise "too many structures are received" 
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
          Laclasse::Log.info("structure: #{structure['code_uai']} will be modifyed")
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
          Laclasse::Log.info("structure: #{structure['code_uai']} will be added")
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
      Laclasse::Log.info("modify or create user is called")

      # three cases 
        # eleves 
        # perseducnat
        # parent
      begin
        data = JSON.parse(@data)
        case @profil
          when "ELEVE"
            modify_or_create_eleves(data)
          when "PARENT"
            modify_or_create_parents(data)
          when "PERSEDUCNAT"
            modify_or_create_presons(data)
          else
            raise "profil not supported"
          end   
      rescue => e
        Laclasse::Log.error(e.message)
      end  
   
    end #end modify_or_create_user

    # -----------------------------------------------------------
    # modify or create eleve
    def modify_or_create_eleves(data)  
      # Example data:  
      #COMPTE profil eleve: 
      #{"profil"=>"ELEVE", "id_sconet"=>"1035780", "id_jointure_aaf"=>"2414273", 
      # "nom"=>"AISSOU", "prenom"=>"Yanis", "date_naissance"=>"15/08/2001", "sexe"=>"M", "date_last_maj_aaf"=>"2013-02-28"}
      # we must capture errors in order to treat all eleves
      data.each do |eleve| 
        begin 
          record = User[:id_jointure_aaf => eleve["id_jointure_aaf"]]
          # search Users for corresponding records
          if record.nil? 
            Laclasse::Log.info("create user #{eleve['id_jointure_aaf']}")
            # find a suitable login for the user
            login = User.find_available_login(eleve["prenom"],eleve["nom"])
            # insert the hash into user table
            # TODO: generate default password algorithm instead of this
            password = eleve['id_jointure_aaf']
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
            Laclasse::Log.info("update eleve #{eleve['id_jointure_aaf']}")
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
          end
        rescue => e 
          Laclasse::Log.error(e.message)
        end     
      end # end each
      Laclasse::Log.info("treated #{data.count} records")
    end

    #------------------------------------------------------------#
    #Compte profil person educ nat
    #{"id_jointure_aaf":"19797","nom":"ANGONIN","prenom":"FRANCOISE","date_naissance":"13/09/1952",
    #"sexe":"F","mail":"Francoise.Angonin@ac-lyon.fr",
    #"mail_academique":"Y","devant_eleve":"O","date_last_maj_aaf":"2013-03-12"}
    def modify_or_create_presons(data)
      data.each do |person| 
        begin 
          found_one = false
          record = User[:id_jointure_aaf => person["id_jointure_aaf"]]
          # search Users for corresponding records
          if record.nil? 
            Laclasse::Log.info("create person #{person['id_jointure_aaf']}")
            # find a suitable login for the user
            login = User.find_available_login(person["prenom"],person["nom"].capitalize)
            # insert the hash into user table
            # TODO: generate default password algorithm instead of this
            password = person['id_jointure_aaf']
            user = User.create(:login => login, 
              :id_jointure_aaf => person["id_jointure_aaf"], :nom => person["nom"], :prenom => person["prenom"].capitalize,
              :date_naissance => person["date_naissance"],:sexe => person["sexe"],
              :password => password)
            
            # add profile ENS to user
            if person["devant_eleve"] == "O"
            profil_id = 'ENS' #??
            etablissement_id = Etablissement[:code_uai => @uai].id
            user.add_profil(etablissement_id, profil_id)
            end 

            # add emails
            if !person["mail"].nil?
              # add email
              if person["mail_academique"] == "Y"
                user.add_email(person["mail"], true)
              else 
                user.add_email(person["mail"])
              end 
            end  
            # add telephones
          else 
            Laclasse::Log.info("update person  #{ person['id_jointure_aaf']}")
            # update where id_jointure_aaf = person["id_jointure_aaf"] with new hash
            record[:nom] = person["nom"] 
            record[:prenom] = person["prenom"].capitalize
            record[:date_naissance] = person["date_naissance"]
            record[:sexe] = person["sexe"]
            record.save

            # add profil to user if not added for person educ nat is not easy
            if person["devant_eleve"] == "O"
            profil_id = 'ENS' #??
            etablissement_id = Etablissement[:code_uai => @uai].id
            record.add_profil(etablissement_id, profil_id)
            end 
             
            # add email
            if !person["mail"].nil?
              # add email
              if person["mail_academique"] == "Y"
                record.add_email(person["mail"], true)
              else 
                record.add_email(person["mail"])
              end 
            end 
            # add telphone, add email    
          end
        rescue => e 
          Laclasse::Log.error(e.message)
        end     
      end # end each
      Laclasse::Log.info("treated #{data.count} records")
    end
    #-----------------------------------------------------------#
    
    # Compte profil parents
    # Example received data
    #{"id_jointure_aaf":"2028471","nom":"AKCHOTE","prenom":"Maria","date_naissance":"","sexe":"F",
    #"adresse":"LE RAMPEAU","code_postal":"69690","ville":"BRULLIOLES",
    #"tel_home":"+33 4 78 25 03 43","tel_work":"","mail":"","date_last_maj_aaf":"2013-03-12"}  
    def modify_or_create_parents(data)
      data.each do |parent| 
        begin 
          record = User[:id_jointure_aaf => parent["id_jointure_aaf"]]
          # search Users for corresponding records
          if record.nil? 
            Laclasse::Log.info("create user #{parent['id_jointure_aaf']}")
            # find a suitable login for the user
            login = User.find_available_login(parent["prenom"],parent["nom"])
            # insert the hash into user table
            # TODO: generate default password algorithm instead of this
            password = parent['id_jointure_aaf']
            user = User.create(:login => login, :id_jointure_aaf => parent["id_jointure_aaf"], :nom => parent["nom"],
              :prenom => parent["prenom"], :date_naissance => parent["date_naissance"],:sexe => parent["sexe"], 
              :adresse => parent["adresse"], :code_postal => parent["code_postal"], :ville => parent["ville"],
              :password => password)
            
            # add profil to user if not added
            profil_id = 'TUT'
            etablissement_id = Etablissement[:code_uai => @uai].id
            user.add_profil(etablissement_id, profil_id)
            
            # add email 
            if !parent["mail"].nil? && parent["mail"] != ""
              user.add_email(parent["mail"])
            end

            # add home telephone
            if !parent["tel_home"].nil? && parent["tel_home"] != ""
              user.add_telephone(parent["tel_home"], 1)
            end

            # add work telephone
            #if !parent["tel_work"].nil? && parent["tel_work"] != ""
              #user.add_telephone(parent["tel_work"], 3)
            #end
          else 
            Laclasse::Log.info("update parent #{parent['id_jointure_aaf']}")
            # update 
            record[:nom] = parent["nom"] 
            record[:prenom] = parent["prenom"]
            record[:date_naissance] = parent["date_naissance"]
            record[:sexe] = parent["sexe"]
            record[:adresse] = parent["adresse"]
            record[:code_postal] = parent["code_postal"]
            record[:ville] = parent["ville"]
            record.save

            # add profil to user if not added
            profil_id = 'TUT'
            etablissement_id = Etablissement[:code_uai => @uai].id
            record.add_profil(etablissement_id, profil_id)
            
            # add email 
            if !parent["mail"].nil? && parent["mail"] != ""
              record.add_email(parent["mail"])
            end

            # add home telephone
            if !parent["tel_home"].nil? && parent["tel_home"] != ""
              record.add_telephone(parent["tel_home"], 1)
            end

            # add work telephone
            if !parent["tel_work"].nil? && parent["tel_work"] != ""
              record.add_telephone(parent["tel_work"], 3)
            end 
          end
        rescue => e 
          Laclasse::Log.error(e.message)
        end     
      end # end each
      Laclasse::Log.info("treated #{data.count} records")
    end 

    # -----------------------------------------------------------
    # synchronize  regroupement 
    # TODO: Modify received data to correspond to 
    # data table
    
    def modify_or_create_regroupement(data)
      Laclasse::Log.info("modify or create Regroupement is called")
        # verify data length 
      if data.length == 0
        raise "no regroupements to be treated" 
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
            Laclasse::Log.info("Modify class  #{regroupement['libelle_aaf']}")
            #modify class 
            # update only code_mef_aaf and date_last_maj_aaf
            record[:code_mef_aaf] = regroupement["code_mef_aaf"]
            record[:date_last_maj_aaf] = regroupement["date_last_maj_aaf"] 
            record[:libelle] = regroupement["libelle"]
            record[:description] = regroupement["description"]
            record.save

          elsif !found_one && regroupement["type_regroupement_id"] == "CLS"
            Laclasse::Log.info("Add class #{regroupement['libelle_aaf']}")
            # create class 
            Regroupement.insert({:libelle_aaf => regroupement["libelle_aaf"],:etablissement_id => etablissement.id, 
              :code_mef_aaf => regroupement["code_mef_aaf"], :type_regroupement_id => regroupement["type_regroupement_id"], 
              :date_last_maj_aaf => regroupement["date_last_maj_aaf"]})


          # received groups data example 
          # {"etablissement":"0690078K","libelle_aaf":"3A GR AL","type_regroupement_id":"GRP",
          # "libelle":"3A Gr Alld2","date_last_maj_aaf":"2013-03-12"}  
          elsif found_one && regroupement["type_regroupement_id"] == "GRP"
            Laclasse::Log.info("Modify group #{regroupement['libelle_aaf']}")
            record[:code_mef_aaf] = regroupement["code_mef_aaf"]
            record[:date_last_maj_aaf] = regroupement["date_last_maj_aaf"] 
            record[:libelle] = regroupement["libelle"]
            record[:description] = regroupement["description"]
            record.save
            
          elsif !found_one && regroupement["type_regroupement_id"] == "GRP"
            Laclasse::Log.info("add group #{regroupement['libelle_aaf']}")
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

    #----------------------------------------------------------------#
    def modify_or_create_rattachement(data)
      # we have three cases 
        # Eleves 
        # Profs 
        # Parents 
      case @profil
        when "ELEVE"
          Laclasse::Log.info("Rattache eleves aux regroupements")
          rattache_eleves_regroupements(data) 
        when "PARENT"
           Laclasse::Log.info("Rattache eleves aux personnes")
          rattache_eleves_persons(data)
        when "PERSEDUCNAT"
           Laclasse::Log.info("Rattache profs aux regroupements")
          rattache_profs_regroupements(data)
        else
          raise "profil is not supported" 
      end      
    end 
    #-----------------------------------------------------------------#
    def rattache_eleves_regroupements(data)
        data.each do |rattachement|
          begin
            # find eleve
            user = User[:id_jointure_aaf => rattachement["id_jointure_aaf"]]
            if user.nil?
              raise "eleve with id_jointure_aaf: #{rattachement['id_jointure_aaf']} does not exist" 
            end
            
            #find regroupement
            if rattachement["type_regroupement"] == 'CLS' 
              regroupement = Regroupement[:type_regroupement_id => rattachement["type_regroupement"], 
              :code_mef_aaf => rattachement["code_mef_aaf"], :libelle_aaf => rattachement["code_aaf"], 
              :etablissement_id => Etablissement[:code_uai => @uai].id]
            elsif  rattachement["type_regroupement"] == 'GRP'    
              regroupement = Regroupement[:type_regroupement_id => rattachement["type_regroupement"], 
              :libelle_aaf => rattachement["code_aaf"], :libelle => rattachement["libelle"],
              :etablissement_id => Etablissement[:code_uai => @uai].id]
            else
              raise "type regroupement is not supported"   
            end

            if regroupement.nil? 
              raise "regroupment with libelle #{rattachement['libelle']} does not exist"
            end

            # rattache eleve to regroupement
            user.add_to_regroupement(regroupement.id)   
               
          rescue => e
            Laclasse::Log.error(e.message)
          end
        end #loop
        Laclasse::Log.info("records treated #{data.count}")      
    end # end rattache_eleves_regroupements
    #---------------------------------------------------------------------#

    # Example received data
    # {"type_alim"=>"Complet", "profil"=>"PERSEDUCNAT", "id_jointure_aaf"=>"15976", "matiere_enseignee_id"=>"006600",
    # "libelle_regroupement"=>"6B", "prof_principal"=>"N", "TYPE"=>"CLS"}

    def rattache_profs_regroupements(data)
      data.each do |rattachement|
        begin
          # find prof 
          prof = User[:id_jointure_aaf => rattachement["id_jointure_aaf"]]
          if prof.nil?
            raise "prof with id_jointure_aaf: #{rattachement['id_jointure_aaf']} does not exist" 
          end
          
          #find regroupement
          regroupement = Regroupement[:type_regroupement_id => rattachement["TYPE"], 
          :libelle_aaf => rattachement["libelle_regroupement"], 
          :etablissement_id => Etablissement[:code_uai => @uai].id]

          if regroupement.nil? 
            raise "regroupement with libelle #{rattachement['libelle_regroupement']} does not exist"
          end

          #find matiere 
          matiere = MatiereEnseignee[:id => rattachement["matiere_enseignee_id"]]

          if matiere.nil?
            raise "matiere with id  #{rattachement['matiere_enseignee_id']} does not exist"
          end  

          # rattache prof to regroupement with matiere id 
          regroupement.add_prof(prof, matiere, rattachement["prof_principal"])
        rescue => e
          Laclasse::Log.error(e.message)
        end     
      end #end loop 

    end # end  rattache_profs_regroupements()  
    #---------------------------------------------------------------------#
    # Example received data 
    #{"type_alim":"Complet","id_jointure_aaf_eleve":"954596","id_jointure_aaf_parent":"1137965","type_relation_eleve_id":"6",
    #"resp_financier":"0","resp_legal":"0","contact":"1","paiement":"0"},
    #
    def rattache_eleves_persons(data)
      data.each do |rattachement|
        begin
          # find eleve 
          eleve = User[:id_jointure_aaf => rattachement["id_jointure_aaf_eleve"]]
          if eleve.nil?
            raise "eleve with id_jointure_aaf: #{rattachement["id_jointure_aaf_eleve"]} does not exist" 
          end

          # find person 
          person = User[:id_jointure_aaf => rattachement["id_jointure_aaf_parent"]]
          if person.nil?
            raise "person with id_jointure_aaf: #{rattachement["id_jointure_aaf_parent"]} does not exist" 
          end
          
          # rattache eleve to person
          eleve.add_or_modify_parent(person, rattachement["type_relation_eleve_id"],  rattachement["resp_financier"], 
            rattachement["resp_legal"], rattachement["contact"], rattachement["paiement"])
        rescue => e
          Laclasse::Log.error(e.message)
        end     
      end #end loop 
    end 

    #----------------------------------------------------------------------#
    # Example received data for fonction 
    # {"id_jointure_aaf"=>"91", "devant_eleve"=>"N", "code_fct"=>"O0040", "lib_fct"=>"ORIENTATION", 
    # "lib_mat"=>"ORIENTATION", "date_last_maj_aaf"=>"2013-03-12"}
    def rattache_fonction_person(data)
      Laclasse::Log.info("rattache fonctions aux person") 
      data.each do |rattachement| 
        begin
          # find person
          person = User[:id_jointure_aaf => rattachement["id_jointure_aaf"]]
          if person.nil?
            raise "person with id_jointure_aaf : #{fonction['id_jointure_aaf']} does not exist"
          end 
          # find function 
          fonction = Fonction[:code_men => rattachement["code_fct"]]
          if fonction.nil?
            raise "fonction with code : #{rattachement["code_fct"]} does not exist"
          end 

          # find profil
          # i'm not sure of this 
          case rattachement["lib_fct"]
            when "ORIENTATION"
              profil_id = "ETA"
            when "ENSEIGNEMENT"
              profil_id = "ENS"
            when "DOCUMENTATION"
              profil_id = "DOC"
            when "DIRECTION"
              profil_id = "DIR"
            when "ASSISTANT D'EDUCATION"
              profil_id = "ETA"
            when "ASSISTANT ETRANGER"
              profil_id ="ETA"
            when "EDUCATION"         
              profil_id ="ETA"
            when "PERSONNELS ADMINISTRATIFS"
              profil_id ="ETA"
            when "PERSONNELS MEDICO-SOCIAUX"
              profil_id ="EVS"
            when "PERSONNELS OUVRIERS ET DE SERVICE"
              profil_id = "COL" # ou ETA
            else 
              profil_id = "COL"    
          end
          # add profil to person
          person.add_profil(Etablissement[:code_uai => @uai].id, profil_id)   
          
          # rattach function to  person
          person.add_fonction(Etablissement[:code_uai => @uai].id, profil_id,rattachement["code_fct"] )  

        rescue => e 
          Laclasse::Log.error(e.message)
        end 
      end   
    end # end  rattache_fonction_person(data)
    #---------------------------------------------------------#
    def dettache_profil(data)
      Laclasse::Log.info("dettachement")
      data.each do |detachement|
        begin
          etablissement_id = Etablissement[:code_uai => @uai]
          puts detachement.inspect
          case detachement["profil"] 
            when "ELEVE"
              Laclasse::Log.info("dettache eleve #{detachement['id_jointure_aaf']} de l\'etablissement #{@uai}")
              dettache_eleve(User[:id_jointure_aaf => detachement['id_jointure_aaf']].id, etablissement_id)
            when "PARENT"
              Laclasse::Log.info("dettache parent #{detachement['id_jointure_aaf']} de l\'etablissement #{@uai}")
              # dettache_eleve(person, profil_id, etablissement_id)  
            when "PERSEDUCNAT"
              Laclasse::Log.info("dettache person_educ_nat #{detachement['id_jointure_aaf']} de l\'etablissement #{@uai}")
              #dettache_person_educ_nat(person, profil_id, etablissement_id)
            else 
              raise " profil reçu n\'est pas valide"
          end   
        rescue => e
          Laclasse::Log.error(e.message)
        end 
      end
    end
    #---------------------------------------------------------#
    def dettache_eleve(eleve_id, etablissement_id)
      # delete profil from profil_user table
      ProfilUser[:profil_id => 'ELV', :user_id => eleve_id, :etablissement_id => etablissement_id].destroy 
      
      # delete fonction from profil_user_has_fonction, eleve has no fonctions
      
      # remove eleve from all regroupements in this etablissement
      EleveRegroupement[:user_id => eleve_id, :regroupement => Regroupement.filter(:etablissement_id => etablissement_id)].destroy

      # delete user roles in the etablissement 
    end
    #--------------------------------------------------------#
    def dettache_parent(person_id, etablissement_id)
       # delete profil from profil_user table
      ProfilUser[:profil_id => 'TUT', :user_id => person_id, :etablissement_id => etablissement_id].destroy

      # delete user roles in the etablissement  
    end
    #--------------------------------------------------------#

    def dettache_pers_educ_nat(person_id, etablissement_id)
      # delete profil from profil_user table
      # il faut trouver les profile 
      # may be pers_educ_nat has many profiles !!
      ProfilUser[:profil_id => 'ENS', :user_id => person_id, :etablissement_id => etablissement_id].destroy 
      
      # delete fonction from profil_user_has_fonction
      ProfilUserFonction[ :user_id => person_id, :etablissement_id => etablissement_id].destroy
      
      # remove prof from all regroupements in which he teaches
      EnseigneRegroupement[:user_id => eleve_id, :regroupement => Regroupement.filter(:etablissement_id => etablissement_id)].destroy

      # delete user roles in the etablissement  
    end  
  end
end