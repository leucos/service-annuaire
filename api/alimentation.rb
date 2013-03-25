#encoding: utf-8

require 'grape'
require 'net/http'
require 'pp'

class AlimentationApi < Grape::API                                                                                                                                                                                     
  format :json
  #  This api contains 2 types of methods
  #  push methods : Post /alimentation/recieve that receives data from alimentation server(annuaire-Ent)
  #  pull methods : Get /alimentation/*  where data is pulled from the server(annuaire-Ent)
  #  to do manual alimentation
    
    # Static variables
    @@recieved = [] #stack for tracing recieved requests
    @@empty_db = false # variable that indicate empty data base in case of complet alimentation(not neccessary)
    #data for an etablissement
    @@services = ["etablissement", "classes", "groupes", "eleves", "pers_educ_nat", "parents", 
      "pers_rel_eleve","rattachements_eleves", "rattachements_profs", "detachements", "fonctions_pen"]
  
  resource :alimentation do
    
    #-----------------------------------------#
    desc "start alimentation"
    get "/started" do
       puts "start alimentation #{Time.now}"
       @@recieved = []
       @@empty_db = true
    end
    
    #-----------------------------------------#
    desc "terminate alimentation"
    get "/terminated" do
      puts "alimentation is terminated at #{Time.now}"
      @@empty_db = false
      #empty stack for other alimentations
      @@recieved = []
      "ok"     
    end
    
    
    #-----------------------------------------#
    # TODO: Add validation to data on receive
    desc "recieve Data from the annuaire Ent Server and treat it"
     params do
        requires :type_import, :type => String, :desc => "import type"
        optional :profil, :type => String, :desc => "user profile"
        requires :uai, :type => String, :desc => "code uai etablissement"
        requires :type_data, :type => String, :desc => "type of data"
        requires :data, :type => String, :desc => "data that is treated" 
      end
    post "/recieve" do 
      puts "--------------------------------------------------------------"
      puts "recieved data from etablissement #{params['uai']} for #{params['type_data']}"
      @@recieved.push("recieved data from etablissement #{params['uai']} for #{params['type_data']}") 
      #algo
      begin 
        logger = Laclasse::Logging.new("log/alimentation_etab_#{params['uai']}.log", Configuration::LOG_LEVEL)
        puts "----------received params from alimentation server-----------\n"
        type_import = params['type_import']
        logger.info("type_import #{type_import}")
        
        profil = params['profil']
        logger.info "profil #{profil}"
        
        uai = params['uai']
        puts "uai #{uai}"
        
        type_data = params['type_data']
        logger.info("type data  #{type_data}")
        puts "type data  #{type_data}"
        
        data = params['data']
        json_data = JSON.parse(data)
        puts "number of received records = #{json_data.count}"
        logger.info("number of received records = #{json_data.count}")
        # instantiate synchronizer
        # TODO: search for a better method for instantiating synchronizer
        start = Time.now
        synchronizer = Alimentation::Synchronizer.new(type_import, uai, profil, type_data, data)
        synchronizer.sync()
        fin = Time.now 
        puts "synchronization took #{fin-start} seconds"
        logger.info("synchronization took #{fin-start} seconds")
        "Data synchronized succesfully"

      rescue => e 
        error!("Bad Request: #{e.message}", 400) 
      end 
    end
    
    #-----------------------------------------#
    desc "get Alimentation etablissements's lists"
    get "/etablissements" do 
      res = Net::HTTP.get_response(URI('http://www.dev.laclasse.com/annuaire/index.php?action=api&service=etablissements'))
      #print res.inspect
      data =  res.body
      puts "----------status---------\n"
      puts res.code       # => '200'
      
      puts "-----------Message--------\n"
      puts res.message 
      
      result = JSON.parse(data)  
      result
    end
    
    #-----------------------------------------#
    #because this method needs a rne par default, i use 000000
    # this api return data per service and code_rne
    desc "get data per service (table) and code_rne"
    params do 
      requires :service, :type => String, :desc => "service"
      optional :uai, :type => String, :desc =>"rne"
    end
    get "/data/:service/:uai" do 
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=fonctions&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=matieres
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=mef
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=etablissements
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=etablissement&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=classes&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=groupes&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=eleves&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=pers_educ_nat&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=parents&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=rattachements_eleves&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=pers_rel_eleve&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=rattachements_profs&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=dettachements&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=fonctions_pen&rne=0690078K

      res = Net::HTTP.get_response(URI("http://www.dev.laclasse.com/annuaire/index.php?action=api&service=#{params[:service]}&rne=#{params[:uai]}"))
      begin
        puts "service = #{params[:service]}"
        puts "uai = #{params[:uai]=="000000"? "all" :params[:uai] }"  
        result = JSON.parse(res.body)
        puts result[0].inspect
        puts "records = #{result.count}"
        result
      rescue => e
        error!("Bad Request: #{e.message}", 400) 
      end
    end
    
    #-----------------------------------------#
    #Todo: errors
    desc "load all data related to an etablissment"
    params do
       requires :uai, :type => String , :desc => "code_rne"
    end
    get "/load/etablissement/:uai" do
      tables = {}
      begin 
        @@services.each do |service| 
          res = Net::HTTP.get_response(URI("http://www.dev.laclasse.com/annuaire/index.php?action=api&service=#{service}&rne=#{params[:uai]}"))
          puts res.code       # => '200'
          puts res.message 
          result = JSON.parse(res.body)
          tables[service] = result   
        end
        #[Test]
        puts tables.count
        tables.each do |table, result|
          puts "#{table} count = #{result.count}}"
        end
        tables 
      rescue => e
         error!("Bad Request: #{e.message}", 400)
      end
    end
    
    #-----------------------------------------#
    # Get reports and bilan info for service or etablissement
    desc "Get reports"
    get "/rapport/:service/:uai" do
      
    end 
    
    #-------------------------------------------------#
    desc "Get bilan etablissement info"
    get "bilan/:type/:uai" do
      # types: bilan_regroupemenets, bilan_comptes
      res = Net::HTTP.get_response(URI("http://www.dev.laclasse.com/annuaire/index.php?action=api&service=#{params[:type]}&rne=#{params[:uai]}")) 
      puts res.code 
      puts res.message
      # parse response
      res.body 
      results = JSON.parse(res.body)    
    end

    #--------------------------------------------------#
    desc "Synchronize Mef education national"
    get "/sync_mef" do 
      service = "mef"
      uai = "000000" # par defaut
      begin
        res = Net::HTTP.get_response(URI("http://www.dev.laclasse.com/annuaire/index.php?action=api&service=#{service}"))
        result = JSON.parse(res.body)
        if result.count > 0 
          Alimentation::Synchronizer.sync_mef(result)
        else
            raise("no MEF data were received ") 
        end
        "Mef syncronized successfully"    
      rescue => e 
        error!("Bad Request: #{e.message}", 400) 
      end 
    end

    #----------------------------------------------------#

    desc "Synchronize Matieres education national"
    get "/sync_mat" do 
      service = "matieres"
      uai = "000000" # par defaut
      begin
        res = Net::HTTP.get_response(URI("http://www.dev.laclasse.com/annuaire/index.php?action=api&service=#{service}"))
        result = JSON.parse(res.body)
        if result.count > 0 
          Alimentation::Synchronizer.sync_matieres(result)
        else
            raise("no Matieres data were received ") 
        end
        "Matieres syncronized successfully"    
      rescue => e 
        error!("Bad Request: #{e.message}", 400) 
      end 
    end 

    #-----------------------------------------------------# 
    desc "Synchronize fonctions eduction national"
    get "/sync_fonc" do 
      service = "fonctions"
      uai = "000000" # par defaut
      begin
        res = Net::HTTP.get_response(URI("http://www.dev.laclasse.com/annuaire/index.php?action=api&service=#{service}&rne=#{uai}"))
        result = JSON.parse(res.body)
        if result.count > 0 
          Alimentation::Synchronizer.sync_fonction(result)
        else
            raise("no Fonctions data were received ") 
        end
        "Fonctions syncronized successfully"    
      rescue => e 
        error!("Bad Request: #{e.message}", 400) 
      end   
    end 
    
    #-----------------------------------------------------# 
    desc "empty an alimented structure (etablissement)"
    params do 
      requires :uai, :type => String , :desc => "code_rne"
    end
    get "/empty/etablissement/:uai" do
      begin 
        # find etablissement
        etab = Etablissement[:code_uai => params[:uai]]
        if etab.nil?
          raise "etablissement n'existe pas"
        else
          etab.destroy 
        end  
      rescue => e 
        error!("Bad Request: #{e.message}", 400)
      end  
    end 
    
    #------------------------------------------------------#
    desc "aliment a structure (etablissement) entirely"
    params do 
      requires :uai, :type => String, :desc => "code_uai"
    end
    get "/aliment/etablissement/:uai" do
      begin
        #etab = Etablissement[:code_uai => params[:uai]]
        #if etab.nil?
          #raise "etablissement n'existe pas"
        #else
        #Url of services
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=etablissement&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=classes&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=groupes&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=eleves&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=pers_educ_nat&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=parents&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=rattachements_eleves&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=pers_rel_eleve&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=rattachements_profs&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=detachements&rne=0690078K
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=fonctions_pen&rne=0690078K
          output = ""
          @@services.each do |service| 
            res = Net::HTTP.get_response(URI("http://www.dev.laclasse.com/annuaire/index.php?action=api&service=#{service}&rne=#{params[:uai]}"))
            #raise "can not pull data #{service} from the server" if res.code != 200       # => '200 
            result = JSON.parse(res.body)
            #["etablissement", "classes", "groupes", "eleves", "pers_educ_nat", "parents", 
            #"pers_rel_eleve","rattachements_eleves", "rattachements_profs", "detachements","fonctions_pen"]
            synchronizer = Alimentation::Synchronizer.new("Complet", params[:uai],"","","")
            #puts service 
            case service
              when "etablissement"
                #synchronizer.type_data = "STRUCTURES"
                start = Time.now 
                synchronizer.modify_or_create_etablissement(result)
                fin = Time.now 
                output += "Synchronize etablissement: #{params[:uai]} \n"
                output += "Synchronization took #{fin-start} seconds \n"

              when "classes"
                #synchronizer.type_data = "CLASSES"
                start = Time.now 
                synchronizer.modify_or_create_regroupement(result)
                fin = Time.now 
                output += "Synchronize Classes:\n"
                output += "number of classes = #{result.count} \n"
                output += "Synchronization took #{fin-start} seconds \n"
                 
              when "groupes"
                #synchronizer.type_data = "GROUPES"
                start = Time.now 
                synchronizer.modify_or_create_regroupement(result)
                fin = Time.now 
                output += "Synchronize groupes:\n"
                output += "number of groups = #{result.count} \n"
                output += "Synchronization took #{fin-start} seconds \n"
                
              when "eleves"
                #synchronizer.type_data = "COMPTES"
                #synchronizer.profil = "ELEVE"
                start = Time.now 
                synchronizer.modify_or_create_eleves(result)
                fin = Time.now 
                output += "Synchronize Eleves: \n"
                output += "number of eleves = #{result.count} \n"
                output += "Synchronization took #{fin-start} seconds \n" 

              when "pers_educ_nat"
                #synchronizer.type_data = "COMPTES"
                #synchronizer.profil = "PERSEDUCNAT"
                start = Time.now 
                synchronizer.modify_or_create_presons(result)
                fin = Time.now 
                output += "Synchronize persons educ nat: \n"
                output += "number of persons = #{result.count} \n"
                output += "Synchronization took #{fin-start} seconds \n"

              when "parents"
                #synchronizer.type_data = "COMPTES"
                #synchronizer.profil = "PARENT"
                start = Time.now 
                synchronizer.modify_or_create_parents(result)
                fin = Time.now 
                output += "Synchronize parents: \n"
                output += "number of parents = #{result.count} \n"
                output += "Synchronization took #{fin-start} seconds \n"

              when "pers_rel_eleve"
                #synchronizer.type_data = "RATTACHEMENTS"
                #synchronizer.profil = "PARENT"
                start = Time.now 
                synchronizer.rattache_eleves_persons(result)
                fin = Time.now 
                output += "Synchronize rattachement eleves persons: \n"
                output += "number of rattachements = #{result.count} \n"
                output += "Synchronization took #{fin-start} seconds \n"

              when "rattachements_eleves" 
                #synchronizer.type_data = "RATTACHEMENTS"
                #synchronizer.profil = "ELEVE"
                start = Time.now 
                synchronizer.rattache_eleves_regroupements(result)
                fin = Time.now 
                output += "Synchronize rattachement eleves regroupement: \n"
                output += "number of rattachements = #{result.count} \n"
                output += "Synchronization took #{fin-start} seconds \n"

              when "rattachement_profs"
                #synchronizer.type_data = "RATTACHEMENTS"
                #synchronizer.profil = "PERSEDUCNAT"
                start = Time.now 
                synchronizer.rattache_profs_regroupements(result)
                fin = Time.now 
                output += "Synchronize rattachement profs regroupement: \n"
                output += "number of rattachements = #{result.count} \n"
                output += "Synchronization took #{fin-start} seconds \n"

              when "detachements"
                #synchronizer.type_data = "DETACHEMENTS"
                start = Time.now 
                synchronizer.dettache_profil(result)
                fin = Time.now 
                output += "Synchronize detachements: \n"
                output += "number of detachements = #{result.count} \n"
                output += "Synchronization took #{fin-start} seconds \n"

              when "fonctions_pen"
                #synchronizer.type_data = "FONCTIONS"
                start = Time.now 
                synchronizer.rattache_fonction_person(result)
                fin = Time.now 
                output += "Synchronize fonction preson educ nat: \n"
                output += "number of fonctions = #{result.count} \n"
                output += "Synchronization took #{fin-start} seconds \n"
              else
                #raise "alimentation type not supported" 
             end             
          end #Loop 
        output
      rescue => e 
        output+="Error: #{e.message} \n"
        #error!("Bad Request: #{e.message}", 400)
      end     
    end
    #---------------------------------------------------------#
  end # resource  
end 