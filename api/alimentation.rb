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
    @@services = ["etablissement", "classes", "groupes", "eleves", "pers_educ_nat", "parents", "pers_rel_eleve"]
    
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
    # Todo: Add validation to data on receive
    desc "recieve Data from the annuaire Ent Server and treat it"
     params do
        requires :type_import, :type => String, :desc => "import type"
        optional :profil, :type => String, :desc => "user profile"
        optional :uai, :type => String, :desc => "code uai etablissement"
        requires :type_data, :type => String, :desc => "type of data"
        requires :data, :type => String, :desc => "data that is treated" 
      end
    post "/recieve" do 
      puts "recieved data from etablissement #{params['uai']} for #{params['type_data']}"
      @@recieved.push("recieved data from etablissement #{params['uai']} for #{params['type_data']}") 
      #algo
      begin 
        puts "----------get params-----------\n"
        data = params['data']
        type_import = params['type_import']
        puts "type_import #{type_import}"
        profil = params['profil']
        puts "profil #{profil}"
        uai = params['uai']
        type_data = params['type_data']
        json_data = JSON.parse(data)
        puts "number of records = #{json_data.count}"
        
        
        #istantiate synchronizer
        synchronizer = Alimentation::Synchronizer.new(type_import, uai, profil, type_data, data)
        synchronizer.sync()
        "ok"
       rescue => e 
         error!("Bad Request: #{e.message}", 400) 
       end 
    end
    
    #-----------------------------------------#
    desc "get Alimentation etablissements's lists"
    get "/etablissements" do 
      res = Net::HTTP.get_response(URI('http://www.dev.laclasse.com/annuaire/index.php?action=api&service=etablissements'))
      #print res.inspect
      
      puts res.inspect
      #pp res
      data =  res.body
      puts "----------status---------\n"
      puts res.code       # => '200'
      
      puts "-----------Message--------\n"
      puts res.message 
      
      result = JSON.parse(data)  
      puts result
      puts "-------------/n"
      puts result.class
      puts "------------/n"
      result
      #response = Net::HTTP.get_response("http://www.dev.laclasse.com", "/annuaire/index.php?action=api&service=etablissements")
      #puts response.body.inspect #this must show the JSON contents
      #puts "success"
    end
    
    #-----------------------------------------#
    #because this method needs a rne par default, i use 000000
    # this api return data per service and code_rne
    desc "get data per service (table) and code_rne"
    params do 
      requires :service, :type => String, :desc => "service"
      optional :rne, :type => String, :desc =>"rne"
    end
    get "/data/:service/:rne" do 
      puts "data"
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
        #http://www.dev.laclasse.com/annuaire/index.php?action=api&service=detachements&rne=0690078K

      res = Net::HTTP.get_response(URI("http://www.dev.laclasse.com/annuaire/index.php?action=api&service=#{params[:service]}&rne=#{params[:rne]}"))
      begin
        puts "service = #{params[:service]}"
        puts "uai = #{params[:rne]=="000000"? "all" :params[:rne] }"  
        result = JSON.parse(res.body)
        puts result[0].inspect
        puts "records = #{result.count}"
      rescue => e
        error!("Bad Request: #{e.message}", 400) 
      end
    end
    
    #-----------------------------------------#
    #Todo: errors
    desc "load all data related to an etablissment"
    params do
       requires :rne, :type => String , :desc => "code_rne"
    end
    get "/load/etablissement/:rne" do
      tables = {}
      begin 
        @@services.each do |service| 
          res = Net::HTTP.get_response(URI("http://www.dev.laclasse.com/annuaire/index.php?action=api&service=#{service}&rne=#{params[:rne]}"))
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
        #[Test]
        "ok"  # return tables 
      rescue => e
         error!("Bad Request: #{e.message}", 400)
      end
    end
    
    #-----------------------------------------#
    # Get reports and bilan info for service or etablissement
    desc "Get reports"
    get "/rapport/:service/:uai" do
      
    end 
    
    #-----------------------------------------#
    desc "Get bilan etablissement info"
    get "bilan/:uai" do 
      
    end
    
  end # resource  
end 