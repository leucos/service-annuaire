#!ruby
#coding: utf-8

# A class that takes alimentation data and feed the mysql database with it 
# TODO: Error management
# TODO: Display execution Time 
module Alimentation
  
  class Synchronizer
    attr_accessor :profil, :type_data, :errorstack, :logger

    def initialize(type_import, uai, profil, type_data, data)
      @type_import = type_import 
      @uai = uai 
      @profil = profil
      @type_data = type_data
      @data = data  # must be transformed to type json , refactor code 
      @logger = Laclasse::Logging.new("log/alimentation_etab_#{@uai}.log", Configuration::LOG_LEVEL)
      @logstack = {}
      # a hash that contains errors
      @errorstack = []
      #if we want to store data temporarly in mongoDB
      #@db =DataBase.connect({:server => "localhost", :db => "mydb"})
    end

    def self.time(label)
      t1 = Time.now
      yield.tap{ Laclasse::Log.info("%s: %.1fs" % [ label, Time.now-t1 ]) }
    end
    
    #-----------------------------------------------------------#
    # data is validated before because of JSON.parse method
    # sync niveau ou mef educ nat
    def self.sync_mef(data) 
      Laclasse::Log.info("synchronize mef educ nationale statrted")
      start = Time.now
      DB.transaction do 
        data.each do |mef_educ_nat|
          begin 
            record = Niveau[:ent_mef_jointure => mef_educ_nat["ENTMefJointure"]]
            if record.nil? # not found => add record 
              Niveau.create(:ent_mef_jointure => mef_educ_nat["ENTMefJointure"], :mef_libelle => mef_educ_nat["ENTLibelleMef"],
                :ent_mef_rattach => mef_educ_nat["ENTMEFRattach"], :ent_mef_stat => mef_educ_nat["ENTMEFSTAT11"]) 
            else  # => modify record 
              record[:mef_libelle] = mef_educ_nat["ENTLibelleMef"]
              record[:ent_mef_rattach] = mef_educ_nat["ENTMEFRattach"]
              record[:ent_mef_stat] = mef_educ_nat["ENTMEFSTAT11"]
              record.save # update
            end
          rescue  => e 
            # change puts to @logger.error
            Laclasse::Log.error(e.message)
          end  
        end # end data.each
      end #transaction 
      fin = Time.now     
      Laclasse::Log.info("#{data.count} Mef_educ_nat entries are synchronized successfully")
      Laclasse::Log.info("synchronization took #{fin-start} seconds")
    end # end sync_mef


    #-----------------------------------------------------------#
    # sync matieres education nationale
    def self.sync_matieres(data)
      Laclasse::Log.info("synchronize matieres educ national")
      # received data 
      # {"code_men":"-","libelle":"ASSISTANT D'EDUCATION","description":"SANS OBJET"}
      start = Time.now
        DB.transaction do  
          data.each do |matiere|
            begin 
              record = MatiereEnseignee[:id => matiere["ENTMatJointure"]]
              if record.nil? # not found => add matiere 
                MatiereEnseignee.create(:id => matiere["ENTMatJointure"], :libelle_long => matiere["ENTLibelleMatiere"]) 
              else  # => modify record 
                record[:libelle_long] = matiere["ENTLibelleMatiere"]
                record.save # update
              end
            rescue  => e 
              # change puts to @logger.error
              Laclasse::Log.error(e.message)
            end  
          end # end data.each
        end # transaction
      fin = Time.now      
      Laclasse::Log.info("#{data.count} Matieres synchronized successfully")
      Laclasse::Log.info("synchronization took #{fin-start} seconds")  
    end

    #-----------------------------------------------------------#
    # sync fonction 
    def self.sync_fonction(data)
      Laclasse::Log.info("synchronize fonctions")
      # received data 
      # {"code_men":"-","libelle":"ASSISTANT D'EDUCATION","description":"SANS OBJET"}
      start = Time.now
        DB.transaction do 
          data.each do |fonction|
            begin 
              record = Fonction[:code_men => fonction["code_men"], :libelle => fonction["libelle"]]
              if record.nil? # not found => add matiere 
                Fonction.create(:code_men => fonction["code_men"], :libelle => fonction["libelle"], 
                  :description => fonction["description"]) 
              else  # => modify record 
                record[:libelle] = fonction["libelle"]
                record[:description] = fonction["description"] 
                record.save # update
              end
            rescue  => e 
              # change puts to @logger.error
              Laclasse::Log.error(e.message)
            end  
          end # end data.each 
        end # transaction 
      fin = Time.now          
      Laclasse::Log.info("#{data.count} Fonctions synchronized successfully")
      Laclasse::Log.info("synchronization took #{fin-start} seconds")    

    end

    #-----------------------------------------------------------# 
    def sync()
      @logger.debug("sync method is called")
      if @type_import == "Delta" 
        sync_delta()
      elsif @type_import =="Complet"
        sync_complet()
      else 
        raise "Alimentation type is not valide"   
      end
    end
    

    #private
    def sync_delta()
      puts "sync_delta is called"
      # database should not be emptied
    end
    
    # -----------------------------------------------------------
    # method responsable for synchronizing complet data
    # i think treatement order is important 
    def sync_complet()
      @logger.debug("sync_complet is called") 
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
          dettache_profil(data)

        when "FONCTIONS"
          puts "FONCTIONS"
          data = JSON.parse(@data)
          rattache_fonction_person(data)  

        else
          raise "data type is not valid"
      end 
    end
    
    # -----------------------------------------------------------
    # synchronize structure
    def modify_or_create_etablissement(data)
      @logger.debug("modify or create structure is called")
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
        # search database for corresponding records
        record = Etablissement[:id => structure["id"], :code_uai => structure["code_uai"]]
        DB.transaction do
          if record.nil? 
            # create
            @logger.debug("structure: #{structure['code_uai']} will be added")
            type_etab = {:type_struct_aaf => structure["type_structure"], :type_contrat => structure["contrat"]}
            type_etab = TypeEtablissement.find_or_create(type_etab)

            Etablissement.create(:id => structure["id"], :code_uai => structure["code_uai"], :siren => structure["siren"],
              :nom => structure["nom"], :adresse => structure["adresse"], :code_postal => structure["code_postal"],
              :ville => structure["ville"],:telephone => structure["telephone"],:fax => structure["fax"], :date_last_maj_aaf => structure["date_last_maj_aaf"],
              :type_etablissement_id => type_etab.id, :last_alimentation => DateTime.now)  
          else 
            # modify
            @logger.debug("structure: #{structure['code_uai']} will be modifyed")
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
            record[:last_alimentation] = DateTime.now
            record.save
          end
        end 
      rescue => e
        @logger.error(e.message)
        @errorstack.push(e.message) 
      end 
    end
    
    # -----------------------------------------------------------
    # syncronize user
    def modify_or_create_user(data)
      @logger.debug("modify or create user is called")
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
        @logger.error(e.message)
        @errorstack.push(e.message)
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
      @logger.debug("modify or create eleve is called")
      etablissement_id = Etablissement[:code_uai => @uai].id
      profil_id = PRF_ELV
      DB.transaction do
        data.each do |eleve| 
          @logger.debug("treat eleve: #{eleve}")
          begin 
            record = User[:id_jointure_aaf => eleve["id_jointure_aaf"]]
            # search Users for corresponding records
            if record.nil? 
              @logger.debug("create eleve with id_jointure: #{eleve['id_jointure_aaf']}")
              # find a suitable login for the user
              login = User.find_available_login(eleve["prenom"],eleve["nom"])
              #login = eleve["nom"]+eleve["prenom"]+eleve["id_jointure_aaf"]
              # insert the hash into user table
              # TODO: generate default password algorithm instead of this
              password = eleve['id_jointure_aaf']
              user = User.create(:id_sconet => eleve["id_sconet"], :login => login, 
                :id_jointure_aaf => eleve["id_jointure_aaf"], :nom => eleve["nom"], :prenom => eleve["prenom"],
                :date_naissance => eleve["date_naissance"],:sexe => eleve["sexe"], :date_creation => eleve["date_last_maj_aaf"],
                :password => password)
              
              # add profil eleve to user
              user.add_profil(etablissement_id, profil_id)
            
              # add emails 
              # add telephones
            else 
              @logger.debug("update eleve with id_jointure: #{eleve['id_jointure_aaf']}")
              # update where id_jointure_aaf = eleve["id_jointure_aaf"] with new hash
              record[:id_sconet] = eleve["id_sconet"]
              record[:nom] = eleve["nom"] 
              record[:prenom] = eleve["prenom"]
              record[:date_naissance] = eleve["date_naissance"]
              record[:sexe] = eleve["sexe"]

              record.save

              # add profil to user if not added
              record.add_profil(etablissement_id, profil_id)
            end
          rescue => e 
            @logger.error(e.message)
            @errorstack.push(e.message)
          end     
        end # end each
      end 
      @logger.info("treated eleves #{data.count} records")
    end

    #------------------------------------------------------------#
    #Compte profil person educ nat
    #{"id_jointure_aaf":"19797","nom":"ANGONIN","prenom":"FRANCOISE","date_naissance":"13/09/1952",
    #"sexe":"F","mail":"Francoise.Angonin@ac-lyon.fr",
    #"mail_academique":"Y","devant_eleve":"O","date_last_maj_aaf":"2013-03-12"}
    def modify_or_create_presons(data)
      @logger.debug("modify or create person educ nat  is called")
      etablissement_id = Etablissement[:code_uai => @uai].id
      DB.transaction do 
        data.each do |person|
          @logger.debug("treat person : #{person}")
          begin 
            found_one = false
            record = User[:id_jointure_aaf => person["id_jointure_aaf"]]
            # search Users for corresponding records
            if record.nil? 
              @logger.debug("create person_educ_nat with id_jointure: #{person['id_jointure_aaf']}")
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
              @logger.debug("update person_educ_nat with id_jointure: #{ person['id_jointure_aaf']}")
              # update where id_jointure_aaf = person["id_jointure_aaf"] with new hash
              record[:nom] = person["nom"] 
              record[:prenom] = person["prenom"].capitalize
              record[:date_naissance] = person["date_naissance"]
              record[:sexe] = person["sexe"]
              record.save

              # add profil to user if not added for person educ nat is not easy
              if person["devant_eleve"] == "O"
              profil_id = 'ENS' #??
              record.add_profil(etablissement_id, profil_id)
              end 
               
              # add email
              if !person["mail"].nil? && !record.email.include?(Email[:adresse => person["mail"]])
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
            @logger.error(e.message)
            @errorstack.push(e.message)
          end     
        end # end each
      end 
      @logger.info("treated person_educ_nat #{data.count} records")
    end
    #-----------------------------------------------------------#
    
    # Compte profil parents
    # Example received data
    #{"id_jointure_aaf":"2028471","nom":"AKCHOTE","prenom":"Maria","date_naissance":"","sexe":"F",
    #"adresse":"LE RAMPEAU","code_postal":"69690","ville":"BRULLIOLES",
    #"tel_home":"+33 4 78 25 03 43","tel_work":"","mail":"","date_last_maj_aaf":"2013-03-12"}  
    def modify_or_create_parents(data)
      @logger.debug("modify or create parents is called")
      #profil_id = 'TUT'
      #etablissement_id = Etablissement[:code_uai => @uai].id
      DB.transaction do 
        data.each do |parent| 
          @logger.debug("treat parent: #{parent}")
          begin 
            record = User[:id_jointure_aaf => parent["id_jointure_aaf"]]
            # search Users for corresponding records
            if record.nil? 
              @logger.debug("create parent with id_jointure: #{parent['id_jointure_aaf']}")
              # find a suitable login for the user
              login = User.find_available_login(parent["prenom"],parent["nom"])
              # insert the hash into user table
              # TODO: generate default password algorithm instead of this
              password = parent['id_jointure_aaf']

              user = User.create(:login => login, :id_jointure_aaf => parent["id_jointure_aaf"], :nom => parent["nom"],
                :prenom => parent["prenom"], :date_naissance => parent["date_naissance"],:sexe => parent["sexe"], 
                :adresse => parent["adresse"], :ville => parent["ville"],
                :password => password)

              # code postal  
              if !parent["code_postal"].nil? && parent["code_postal"] != ""
                user[:code_postal] = parent["code_postal"]
                user.save
              end 
                 
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
                user.add_telephone(parent["tel_home"])
              end

              # add work telephone
              if !parent["tel_work"].nil? && parent["tel_work"] != ""
                user.add_telephone(parent["tel_work"],TYP_TEL_TRAV)
              end
            else 
              @logger.debug("update parent with id_jointure: #{parent['id_jointure_aaf']}")
              # update 
              record[:nom] = parent["nom"] 
              record[:prenom] = parent["prenom"]
              record[:date_naissance] = parent["date_naissance"]
              record[:sexe] = parent["sexe"]
              record[:adresse] = parent["adresse"]
              if !parent["code_postal"].nil? && parent["code_postal"] != ""
                record[:code_postal] = parent["code_postal"]
              end  
              record[:ville] = parent["ville"]
              record.save

              # add profil to user if not added
              profil_id = 'TUT'
              etablissement_id = Etablissement[:code_uai => @uai].id
              record.add_profil(etablissement_id, profil_id)
              
              # update email 
              if !parent["mail"].nil? && parent["mail"] != "" && !record.email.include?(Email[:adresse => parent["mail"]])
                record.add_email(parent["mail"])
              end
                
              # update telephone
              if !parent["tel_home"].nil? && parent["tel_home"] != "" && !record.telephone.include?(Telephone[:numero => parent["tel_home"].delete(" "), :user_id => record.id])
                record.add_telephone(parent["tel_home"])
              end

              # update work telephone
              if !parent["tel_work"].nil? && parent["tel_work"] != "" && !record.telephone.include?(Telephone[:numero => parent["tel_work"].delete(" "), :user_id => record.id])
                record.add_telephone(parent["tel_work"],TYP_TEL_TRAV)
              end 
            end
          rescue => e 
            @logger.error(e.message)
            @errorstack.push(e.message)
          end     
        end # end each
      end # Transaction  
     @logger.info("treated parents #{data.count} records")
    end 

    # -----------------------------------------------------------
    # synchronize  regroupement 
    # TODO: Modify received data to correspond to 
    # data table
    
    def modify_or_create_regroupement(data)
      @logger.debug("modify or create Regroupement is called")
        # verify data length 
      DB.transaction do 
        data.each do |regroupement|
          # search Regroupements table  for corresponding records
          # i do not know if libelle_aaf is unique ?!!
          @logger.debug("treat regroupement: #{regroupement}")
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
              @logger.debug("Modify class: #{regroupement['libelle_aaf']}")
              #modify class 
              # update only code_mef_aaf and date_last_maj_aaf
              record[:code_mef_aaf] = regroupement["code_mef_aaf"]
              record[:date_last_maj_aaf] = regroupement["date_last_maj_aaf"] 
              record[:libelle] = regroupement["libelle"]
              record[:description] = regroupement["description"]
              record.save

            elsif !found_one && regroupement["type_regroupement_id"] == "CLS"
              @logger.debug("Add class: #{regroupement['libelle_aaf']}")
              # create class 
              Regroupement.create(:libelle_aaf => regroupement["libelle_aaf"],:etablissement_id => etablissement.id, 
                :code_mef_aaf => regroupement["code_mef_aaf"], :type_regroupement_id => regroupement["type_regroupement_id"], 
                :date_last_maj_aaf => regroupement["date_last_maj_aaf"])


            # received groups data example 
            # {"etablissement":"0690078K","libelle_aaf":"3A GR AL","type_regroupement_id":"GRP",
            # "libelle":"3A Gr Alld2","date_last_maj_aaf":"2013-03-12"}  
            elsif found_one && regroupement["type_regroupement_id"] == "GRP"
              @logger.debug("Modify group: #{regroupement['libelle_aaf']}")
              record[:code_mef_aaf] = regroupement["code_mef_aaf"]
              record[:date_last_maj_aaf] = regroupement["date_last_maj_aaf"] 
              record[:libelle] = regroupement["libelle"]
              record[:description] = regroupement["description"]
              record.save
              
            elsif !found_one && regroupement["type_regroupement_id"] == "GRP"
              @logger.debug("Add group: #{regroupement['libelle_aaf']}")
              Regroupement.create(:libelle_aaf => regroupement["libelle_aaf"],:etablissement_id => etablissement.id, 
                :code_mef_aaf => regroupement["code_mef_aaf"], :type_regroupement_id => regroupement["type_regroupement_id"], 
                :date_last_maj_aaf => regroupement["date_last_maj_aaf"], :libelle => regroupement["libelle"])
               
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
            @logger.error(e.message)
            @errorstack.push(e.message)
          end

        end #end loop
      end # Transaction   
      @logger.info("treated regoupements #{data.count} records")

    end # end modify_or_create_regroupement

    #----------------------------------------------------------------#
    def modify_or_create_rattachement(data)
      case @profil
        when "ELEVE"
          rattache_eleves_regroupements(data) 
        when "PARENT"
          rattache_eleves_persons(data)
        when "PERSEDUCNAT"
          rattache_profs_regroupements(data)
        else
          raise "profil is not supported" 
      end      
    end 
    #-----------------------------------------------------------------#
    def rattache_eleves_regroupements(data)
      @logger.debug("Rattache eleves aux regroupements")
      DB.transaction do
        data.each do |rattachement|
          @logger.debug("rattachement : #{rattachement}")
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
            @logger.debug("rattache eleve with #{rattachement['id_jointure_aaf']} to groupe #{rattachement['code_aaf']}")
            user.add_to_regroupement(regroupement.id)   
               
          rescue => e
            @logger.error(e.message)
            @errorstack.push(e.message)
          end
        end #loop
      end # transaction
      @logger.info("treated rattachement eleves regroupements#{data.count}")      
    end # end rattache_eleves_regroupements
    #---------------------------------------------------------------------#

    # Example received data
    # {"type_alim"=>"Complet", "profil"=>"PERSEDUCNAT", "id_jointure_aaf"=>"15976", "matiere_enseignee_id"=>"006600",
    # "libelle_regroupement"=>"6B", "prof_principal"=>"N", "TYPE"=>"CLS"}

    def rattache_profs_regroupements(data)
      @logger.debug("Rattache profs aux regroupements")
      DB.transaction do 
        data.each do |rattachement|
          @logger.debug("rattachement : #{rattachement}")
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
            #puts matiere.inspect

            if matiere.nil?
              raise "matiere with id  #{rattachement['matiere_enseignee_id']} does not exist"
            end  

            # rattache prof to regroupement with matiere id 
            @logger.debug("rattache prof with #{rattachement['id_jointure_aaf']} to groupe #{rattachement['libelle_regroupement']}")
            regroupement.add_prof(prof, matiere.id, rattachement["prof_principal"])
          rescue => e
            @logger.error(e.message)
            @errorstack.push(e.message)
          end     
        end #end loop 
      end # Transaction
      @logger.info("treated rattachement profs regroupements#{data.count}")    
    end # end  rattache_profs_regroupements()  
    #---------------------------------------------------------------------#
    # Example received data 
    #{"type_alim":"Complet","id_jointure_aaf_eleve":"954596","id_jointure_aaf_parent":"1137965","type_relation_eleve_id":"6",
    #"resp_financier":"0","resp_legal":"0","contact":"1","paiement":"0"},
    #
    def rattache_eleves_persons(data)
      @logger.debug("Rattache eleves aux parents")
      DB.transaction do 
        data.each do |rattachement|
          @logger.debug("rattachement : #{rattachement}")
          begin
            # find eleve 
            eleve = User[:id_jointure_aaf => rattachement["id_jointure_aaf_eleve"]]
            if eleve.nil?
              raise "eleve with id_jointure_aaf: #{rattachement["id_jointure_aaf_eleve"]} does not exist" 
            end

            # find person 
            person = User[:id_jointure_aaf => rattachement["id_jointure_aaf_parent"]]
            if person.nil?
              raise "parent with id_jointure_aaf: #{rattachement["id_jointure_aaf_parent"]} does not exist" 
            end
            
            # rattache eleve to person
             @logger.debug("rattache eleve with id_jointure_aaf: #{rattachement['id_jointure_aaf_eleve']} to person with id_jointure_aaf: #{rattachement["id_jointure_aaf_parent"]}")
            eleve.add_parent(person, rattachement["type_relation_eleve_id"],  rattachement["resp_financier"], 
              rattachement["resp_legal"], rattachement["contact"], rattachement["paiement"])
          rescue => e
            @logger.error(e.message)
            @errorstack.push(e.message)
          end     
        end #end loop
      end #transaction 
      @logger.info("treated rattachement eleves persons #{data.count}")  
    end 

    #----------------------------------------------------------------------#
    # Example received data for fonction 
    # {"id_jointure_aaf"=>"91", "devant_eleve"=>"N", "code_fct"=>"O0040", "lib_fct"=>"ORIENTATION", 
    # "lib_mat"=>"ORIENTATION", "date_last_maj_aaf"=>"2013-03-12"}
    def rattache_fonction_person(data)
      @logger.debug("rattache fonctions aux person")
      DB.transaction do  
        data.each do |rattachement| 
          @logger.debug("rattachement : #{rattachement}")
          begin
            # find person
            person = User[:id_jointure_aaf => rattachement["id_jointure_aaf"]]
            if person.nil?
              raise "person with id_jointure_aaf : #{fonction['id_jointure_aaf']} does not exist"
            end 
            # find function 
            fonction = Fonction[:code_men => rattachement["code_fct"], :libelle => rattachement["lib_fct"]]
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
              when "PERSONNELS ADMINISTRATIFS" || "ADMINSTRATION"
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
            @logger.debug("rattache pers_educ_nat #{rattachement["id_jointure_aaf"]} with a function #{rattachement["code_fct"]}")
            person.add_fonction(Etablissement[:code_uai => @uai].id, profil_id,fonction.id)  

          rescue => e 
            @logger.error(e.message)
            @errorstack.push(e.message)
          end 
        end
      end # transaction 
      @logger.info("treated rattachement fonctions persons #{data.count}")      
    end # end  rattache_fonction_person(data)
    #---------------------------------------------------------#
    def dettache_profil(data)
      @logger.debug("dettachement")
      DB.transaction do 
        data.each do |detachement|
          @logger.debug("detachement : #{detachement}")
          begin
            etablissement = Etablissement[:code_uai => @uai]
            if etablissement.nil?
              raise "etablissement n'existe pas"
            end
            etablissement_id = etablissement.id 

            user = User[:id_jointure_aaf => detachement['id_jointure_aaf']]

            case detachement["profil"] 
              when "ELEVE"
                @logger.debug("dettache eleve #{detachement['id_jointure_aaf']} de l\'etablissement #{@uai}")
                if user.nil? 
                  raise "l'eleve avec id_jointure_aaf: #{detachement['id_jointure_aaf']} n'exist pas"
                else 
                  dettache_eleve(user.id, etablissement_id)
                end 
              when "PARENT"
                @logger.debug("dettache parent #{detachement['id_jointure_aaf']} de l\'etablissement #{@uai}")
                if user.nil? 
                  raise "le parent avec id_jointure_aaf: #{detachement['id_jointure_aaf']} n'exist pas"
                else 
                  dettache_parent(user.id, etablissement_id)
                end 
              when "PERSEDUCNAT"
                @logger.debug("dettache person_educ_nat #{detachement['id_jointure_aaf']} de l\'etablissement #{@uai}")
                if user.nil? 
                  raise "la personne educ national avec id_jointure_aaf: #{detachement['id_jointure_aaf']} n'exist pas"
                else 
                  dettache_pers_educ_nat(user.id, etablissement_id)
                end 
              else 
                raise " profil reçu n\'est pas valide"
            end   
          rescue => e
            @logger.error(e.message)
            @errorstack.push(e.message)
          end 
        end
      end # transaction
      @logger.info("treated detachements #{data.count}") 
    end
    #---------------------------------------------------------#
    def dettache_eleve(eleve_id, etablissement_id)
      # delete profil from profil_user table
      profil = ProfilUser[:profil_id => 'ELV', :user_id => eleve_id, :etablissement_id => etablissement_id]
      if profil
        profil.destroy
      end   
      
      # remove eleve from all regroupements in this etablissement
      eleve_regroupement = EleveDansRegroupement[:user_id => eleve_id, :regroupement => Regroupement.where(:etablissement_id => etablissement_id)]
      if eleve_regroupement
        eleve_regroupement.destroy
      end  
      
      # delete user roles in the etablissement 
      roles_user = RoleUser.filter(:user_id => eleve_id, :etablissement_id => etablissement_id)
      if roles_user.count > 0
        roles_user.each do |role|
          role.destroy
        end   
      end  

    end
    #--------------------------------------------------------#
    def dettache_parent(person_id, etablissement_id)
      # delete profil from profil_user table
      profil = ProfilUser[:profil_id => 'TUT', :user_id => person_id, :etablissement_id => etablissement_id]
      if profil
        profil.destroy
      end

      # delete user roles in the etablissement
      roles_user = RoleUser.filter(:user_id => eleve_id, :etablissement_id => etablissement_id)
      if roles_user.count > 0
        roles_user.each do |role|
          role.destroy
        end   
      end   
    end

    #--------------------------------------------------------#
    def dettache_pers_educ_nat(person_id, etablissement_id)
      # delete profil from profil_user table
      # il faut trouver les profils 
      
      # ProfilUser[:profil_id => 'ENS', :user_id => person_id, :etablissement_id => etablissement_id].destroy 
      user_profils = ProfilUser.filter('profil_id NOT IN ?', ['TUT']).where(:user_id => person_id, :etablissement_id => etablissement_id)
      
      # may be pers_educ_nat has many profiles !!
      if ! user_profils.empty?
        user_profils.each do |profil|
          profil.destroy
        end
      end      

      # delete fonction from profil_user_has_fonction
      # user may have many functions in the structure ( etablissement)
      user_fonctions = ProfilUserFonction.where(:user_id => person_id, :etablissement_id => etablissement_id)
      if ! user_fonctions.empty?
        user_fonctions.each do |fonction| 
          fonction.destroy
        end  
      end
      
      # remove prof from all regroupements in which he teaches
      user_regroupements = EnseigneDansRegroupement.where(:user_id => person_id, :regroupement => Regroupement.filter(:etablissement_id => etablissement_id))
      if ! user_regroupements.empty?
        user_regroupements.each do |attachement|
          attachement.destroy
        end
      end     
      
      # delete user roles in the etablissement
      roles_user = RoleUser.filter(:user_id => eleve_id, :etablissement_id => etablissement_id)
      if roles_user.count > 0
        roles_user.each do |role|
          role.destroy
        end   
      end   
    end  
  end
end