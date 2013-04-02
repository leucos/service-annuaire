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
    get "/start" do
       Laclasse::Log.info("start alimentation #{Time.now}")
       @@recieved_requests = {}
      "Le stack est initializé et l'alimentation a commence"
    end
    
    #-----------------------------------------#
    desc "terminate alimentation"
    get "/terminate" do
      Laclasse::Log.info("alimentation is terminated at #{Time.now}")
      puts @@recieved_requests.inspect
      temp = @@recieved_requests
      #empty stack for other alimentations
      @@recieved_requests = {}
      #temp
      "l'alimentation a termine"

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
      Laclasse::Log.info("--------------------------------------------------------------")
      Laclasse::Log.info("recieved data from etablissement #{params['uai']} for #{params['type_data']}")
      #algo
      begin
        # save the received requests
        # if (@@recieved_requests.has_key?(params['uai'])) && !(@@recieved_requests[params['uai']].include?("#{params['type_data']}:#{params['profil']}"))
        #   @@recieved_requests[params['uai']].push("#{params['type_data']}:#{params['profil']}")
        # elsif !(@@recieved_requests.has_key?(params['uai']))
        #   @@recieved_requests[params['uai']] = []
        #   @@recieved_requests[params['uai']].push("#{params['type_data']}:#{params['profil']}")
        # end    
        logger = Laclasse::Logging.new("log/alimentation_etab_#{params['uai']}.log", Configuration::LOG_LEVEL)
        puts "----------received params from alimentation server-----------\n"
        type_import = params['type_import']
        #logger.info("type_import #{type_import}")
        
        profil = params['profil']
        #logger.info "profil #{profil}"
        
        uai = params['uai']
        logger.info "etablissement #{uai}"
        puts "uai #{uai}"
        
        type_data = params['type_data']
        logger.info("type data  #{type_data}")
        logger.info "profil #{profil}"
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
      #result
      {"data" => result, "count" => result.count}
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
        puts "uai = #{ params[:uai] == "000000" ? "all" : params[:uai] }"  
        result = JSON.parse(res.body)
        #puts result[0].inspect
        records = result.count
        #output  instead of result
        {"data" => result, "count" => records}
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
          #puts res.code       # => '200'
          #puts res.message 
          result = JSON.parse(res.body)
          tables[service] = result   
        end
        #[Test]
        puts tables.count
        tables.each do |table, result|
          #puts "#{table} count = #{result.count}}"
        end
        tables 
      rescue => e
         error!("Bad Request: #{e.message}", 400)
      end
    end
     
    #-------------------------------------------------#
    desc "Get bilan etablissement info"
    get "bilan/:type/:uai" do
      # types: bilan_regroupemenets, bilan_comptes
      begin 
        res = Net::HTTP.get_response(URI("http://www.dev.laclasse.com/annuaire/index.php?action=api&service=#{params[:type]}&rne=#{params[:uai]}")) 
        results = JSON.parse(res.body)
        if params[:type] == "bilan_comptes"
          #eleves
          no_of_eleves = results[0]["ELEVE"].select {|r| r["etat_previsu"] == "OK"}.empty? ? 0 : results[0]["ELEVE"].select {|r| r["etat_previsu"] == "OK"}[0]["nb"]
          deleted_eleves = results[0]["ELEVE"].select {|r| r["etat_previsu"] == "DELETED"}.empty? ? 0 : results[0]["ELEVE"].select {|r| r["etat_previsu"] == "DELETED"}[0]["nb"] 
          error_eleves = results[0]["ELEVE"].select {|r| r["etat_previsu"]== "ERROR"}.empty? ? 0 : results[0]["ELEVE"].select {|r| r["etat_previsu"]== "ERROR"}[0]["nb"]
          eleves = {"nb" => no_of_eleves, "deleted" => deleted_eleves, "errors" => error_eleves}

          # parents
          no_of_parents = results[1]["PARENT"].select {|r| r["etat_previsu"] == "OK"}.empty? ? 0 : results[1]["PARENT"].select {|r| r["etat_previsu"] == "OK"}[0]["nb"]
          deleted_parents = results[1]["PARENT"].select {|r| r["etat_previsu"] == "DELETED"}.empty? ? 0 : results[1]["PARENT"].select {|r| r["etat_previsu"] == "DELETED"}[0]["nb"] 
          error_parents = results[1]["PARENT"].select {|r| r["etat_previsu"]== "ERROR"}.empty? ? 0 : results[1]["PARENT"].select {|r| r["etat_previsu"]== "ERROR"}[0]["nb"]
          parents = {"nb" => no_of_parents, "deleted" => deleted_parents, "errors" => error_parents}

          # person educ nat
          no_of_persons = results[2]["PERSEDUCNAT"].select {|r| r["etat_previsu"] == "OK"}.empty? ? 0 : results[2]["PERSEDUCNAT"].select {|r| r["etat_previsu"] == "OK"}[0]["nb"]
          deleted_persons = results[2]["PERSEDUCNAT"].select {|r| r["etat_previsu"] == "DELETED"}.empty? ? 0 : results[2]["PERSEDUCNAT"].select {|r| r["etat_previsu"] == "DELETED"}[0]["nb"] 
          error_persons = results[2]["PERSEDUCNAT"].select {|r| r["etat_previsu"]== "ERROR"}.empty? ? 0 : results[2]["PERSEDUCNAT"].select {|r| r["etat_previsu"]== "ERROR"}[0]["nb"]
          persons = {"nb" => no_of_parents, "deleted" => deleted_parents, "errors" => error_parents}

          {"eleves" => eleves, "parents"=> parents, "pers_educ_nat" => persons}

        else
          results  
        end     
      rescue => e 
        error!("Bad Request: #{e.message}", 400)
      end  
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
        {"niveaux" => result.count}    
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
        {"matieres" => result.count}   
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
        {"fonctions" => result.count}  
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
        infostack = {}
        infostack["errors"] = []
        @@services.each do |service| 
          begin
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
              infostack["etablissement"] = {:uai => params[:uai], :sync_time => fin-start, 
                :errors => synchronizer.errorstack} 

            when "classes"
              #synchronizer.type_data = "CLASSES"
              start = Time.now 
              synchronizer.modify_or_create_regroupement(result)
              fin = Time.now 
              output += "Synchronize Classes:\n"
              output += "number of classes = #{result.count} \n"
              output += "Synchronization took #{fin-start} seconds \n"
              infostack["classes"] = {:count => result.count, :sync_time => fin-start, 
                :errors => synchronizer.errorstack} 

            when "groupes"
              #synchronizer.type_data = "GROUPES"
              start = Time.now 
              synchronizer.modify_or_create_regroupement(result)
              fin = Time.now 
              output += "Synchronize groupes:\n"
              output += "number of groups = #{result.count} \n"
              output += "Synchronization took #{fin-start} seconds \n"
              infostack["groupes"] = {:count => result.count, :sync_time => fin-start, 
                :errors => synchronizer.errorstack} 

            when "eleves"
              #synchronizer.type_data = "COMPTES"
              #synchronizer.profil = "ELEVE"
              start = Time.now 
              synchronizer.modify_or_create_eleves(result)
              fin = Time.now 
              output += "Synchronize Eleves: \n"
              output += "number of eleves = #{result.count} \n"
              output += "Synchronization took #{fin-start} seconds \n" 
              infostack["eleves"] = {:count => result.count, :sync_time => fin-start, 
                :errors => synchronizer.errorstack} 

            when "pers_educ_nat"
              #synchronizer.type_data = "COMPTES"
              #synchronizer.profil = "PERSEDUCNAT"
              start = Time.now 
              synchronizer.modify_or_create_presons(result)
              fin = Time.now 
              output += "Synchronize persons educ nat: \n"
              output += "number of persons = #{result.count} \n"
              output += "Synchronization took #{fin-start} seconds \n"
              infostack["pers_educ_nat"] = {:count => result.count, :sync_time => fin-start, 
                :errors => synchronizer.errorstack} 

            when "parents"
              #synchronizer.type_data = "COMPTES"
              #synchronizer.profil = "PARENT"
              start = Time.now 
              synchronizer.modify_or_create_parents(result)
              fin = Time.now 
              output += "Synchronize parents: \n"
              output += "number of parents = #{result.count} \n"
              output += "Synchronization took #{fin-start} seconds \n"
              infostack["parent"] = {:count => result.count, :sync_time => fin-start, 
                :errors => synchronizer.errorstack} 

            when "pers_rel_eleve"
              #synchronizer.type_data = "RATTACHEMENTS"
              #synchronizer.profil = "PARENT"
              start = Time.now 
              synchronizer.rattache_eleves_persons(result)
              fin = Time.now 
              output += "Synchronize rattachement eleves persons: \n"
              output += "number of rattachements = #{result.count} \n"
              output += "Synchronization took #{fin-start} seconds \n"
              infostack["pers_rel_eleve"] = {:count => result.count, :sync_time => fin-start, 
                :errors => synchronizer.errorstack} 

            when "rattachements_eleves" 
              #synchronizer.type_data = "RATTACHEMENTS"
              #synchronizer.profil = "ELEVE"
              start = Time.now 
              synchronizer.rattache_eleves_regroupements(result)
              fin = Time.now 
              output += "Synchronize rattachement eleves regroupement: \n"
              output += "number of rattachements = #{result.count} \n"
              output += "Synchronization took #{fin-start} seconds \n"
              infostack["rattachement_eleves"] = {:count => result.count, :sync_time => fin-start, 
                :errors => synchronizer.errorstack} 

            when "rattachements_profs"
              #synchronizer.type_data = "RATTACHEMENTS"
              #synchronizer.profil = "PERSEDUCNAT"
              start = Time.now 
              synchronizer.rattache_profs_regroupements(result)
              fin = Time.now 
              output += "Synchronize rattachement profs regroupement: \n"
              output += "number of rattachements = #{result.count} \n"
              output += "Synchronization took #{fin-start} seconds \n"
              infostack[:rattachement_profs] = {:count => result.count, :sync_time => fin-start, 
                :errors => synchronizer.errorstack} 

            when "detachements"
              #synchronizer.type_data = "DETACHEMENTS"
              start = Time.now 
              synchronizer.dettache_profil(result)
              fin = Time.now 
              output += "Synchronize detachements: \n"
              output += "number of detachements = #{result.count} \n"
              output += "Synchronization took #{fin-start} seconds \n"
              infostack["detachements"] = {:count => result.count, :sync_time => fin-start, 
                :errors => synchronizer.errorstack}  

            when "fonctions_pen"
              #synchronizer.type_data = "FONCTIONS"
              start = Time.now 
              synchronizer.rattache_fonction_person(result)
              fin = Time.now 
              output += "Synchronize fonction preson educ nat: \n"
              output += "number of fonctions = #{result.count} \n"
              output += "Synchronization took #{fin-start} seconds \n"
              infostack["fonction_pen"] = {:count => result.count, :sync_time => fin-start, 
                :errors => synchronizer.errorstack} 
            else
              raise "alimentation type not supported #{service}" 
           end
          #infostack["errors"] + synchronizer.errorstack  
          rescue => e 
           output+="Error: #{e.message} \n"
           infostack["errors"].push(e.message)
            #error!("Bad Request: #{e.message}", 400)
          end               
        end #Loop 
      #output
      infostack   
    end
    #---------------------------------------------------------#
  end # resource  
end 