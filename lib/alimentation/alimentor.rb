#!ruby
#coding: utf-8
require 'zlib'
require 'archive/tar/minitar'

require __DIR__('parser_xml_menesr')
require __DIR__('diff_generator')
require __DIR__('diff_view')
require __DIR__('db_sync')

# TODO = distinguish between delta and complete alimentation
#Super classe qui prend un fichier targz (complet ou delta) de l'académie et alimente automatiquement
#Tous les établissements présents dans l'archive
module Alimentation
  class Alimentor
    attr_accessor :etb_file_map, :archive_name, :date_alim, :parser
    #Attribut présent dans le nom des fichiers
    @@complet_name = "Complet"
    @@delta_name = "Delta"
    
     
    #-------------------------------------------------------------#   
    def initialize(archive_name)
      @parser = ParserXmlMongo.new
      @archive_name = archive_name
      @is_complet = File.basename(@archive_name).index(@@complet_name) != nil
      @is_delta = File.basename(@archive_name).index(@@delta_name) != nil
      puts @is_complet
      #if !is_complet? || !is_delta?
        #raise "Archive is not Delta nor Complete"
      #end
      
      #key : code UIA de l'établissement, value: Array de fichiers d'alimentation de l'établissement
      @etb_file_map = Hash.new
      name_split = File.basename(@archive_name).split(".")
      @date_alim = Date.parse(name_split[1]) if name_split.length > 1
      @temp_dir = "tmp"
    end
     
    #-------------------------------------------------------------# 
    def clean_tmp_dir
      if Dir.exists?(@temp_dir)
        Dir.foreach(@temp_dir) do |f|
          File.delete(File.join(@temp_dir,f)) if File.file?(File.join(@temp_dir,f))
        end
      end
    end
     
    #-------------------------------------------------------------# 
    def unpack_archive
      clean_tmp_dir()

      Zlib::GzipReader.open(@archive_name) do |tgz|
        #Unpack the tar, this way it will be easier to work with xml files
        #This may take a while...
        Laclasse::Log.info("#{@archive_name} is good")
        Archive::Tar::Minitar.unpack(tgz, @temp_dir)
      end

      ok = Dir.exists?(@temp_dir)
      Laclasse::Log.error("Temp dir not created aborting alimentation") unless ok
      return ok
    end

    #-------------------------------------------------------------# 
    def list_all_etb
      #Then list all etablissements and xml files
      Dir.foreach(@temp_dir) do |name|
        file_path = File.join(@temp_dir, name)
        if File.file?(file_path) and File.extname(name) == ".xml"
          name_split = name.split("_")
          if name_split.length > 2
              code_uai = name_split[1]
              @etb_file_map[code_uai] = Array.new if @etb_file_map[code_uai].nil?
              #On accepte que les fichiers Complet ou Delta en fonction du type d'alimentation
              if (@is_complet and name_split[2] == @@complet_name) or
               (!@is_complet and name_split[2] == @@delta_name)
                @etb_file_map[code_uai].push(file_path)
              end
          end
        end
      end
    end
    #-------------------------------------------------------------#  
    #(v2) list files by categorie
    # not necessary for our file format
    def list_all_files 
      Dir.foreach(@temp_dir) do |file|
        file_path = File.join(@temp_dir, file)
          if File.file?(file_path) and File.extname(file) == ".xml"
            name_split = file.split("_")
            if name_split.length > 4
              categorie = name_split[4]
              @etb_file_map[categorie] = Array.new if @etb_file_map[categorie].nil?
              if (name_split[2] == @@complet_name) or
               ( name_split[2] == @@delta_name)
                @etb_file_map[categorie].push(file_path)
              end
            end
          end
        end  
    end
     
    #---------------------------------------------------------------# 
    #-----Extract files and build a hash of files per etablissement
    #---------------------------------------------------------------#
    def prepare_alimentation
      Laclasse::Log.info("prepare_alimentation")
      time("prepere alimentation took") do 
        ok = unpack_archive()
        list_all_etb() if ok
      end 

      return @etb_file_map.length > 0
    end

    
    # (v2) parse all etab -------------------------------------------#
    def parse_all_etb
      begin
        # new Mongo db parser using mongo db
        #cur_etb_data = parser.parse_etb(uai, file_list)
        @parser.parse_all_etb(@etb_file_map)
        
        
        unless @parser.db.collection_names.empty?
          Laclasse::Log.info("Generate diff")
          #diff_generator = DiffGenerator.new(uai, cur_etb_data, @is_complet)
          #diff = diff_generator.generate_diff_etb()
  
          #puts diff
  
          ##Laclasse::Log.info("Generate diff_view")
          ##diff_view = DiffView.new
          ##diff_view.generate_html(uai, diff, @date_alim, @is_complet)
  
          Laclasse::Log.info("Synchronize DB")
          ##sync = DbSync.new
          ##sync.sync_db(diff)
        end
      rescue => e
        Laclasse::Log.error("#{e.message}")
        #puts "#{e.backtrace}"
      end
    end
    
    # (v2) parse une seule etab -------------------------------------------#
    def parse_etb(uai)
      begin
        # new Mongo db parser using mongo db
        if @etb_file_map.keys.include?(uai)
          # may be we need to empty the database !!
          @parser.parse_etb(uai, @etb_file_map[uai])
                  
          
          unless @parser.db.collection_names.empty?
            Laclasse::Log.info("Generate diff")
            #diff_generator = DiffGenerator.new(uai, cur_etb_data, @is_complet)
            #diff = diff_generator.generate_diff_etb()
    
            #puts diff
    
            ##Laclasse::Log.info("Generate diff_view")
            ##diff_view = DiffView.new
            ##diff_view.generate_html(uai, diff, @date_alim, @is_complet)
    
            Laclasse::Log.info("Synchronize DB")
            ##sync = DbSync.new
            ##sync.sync_db(diff)
          end
        else
           raise "Etablissement n'existe pas" 
        end 
      rescue => e
        Laclasse::Log.error("#{e.message}")
        #puts "#{e.backtrace}"
      end
    end
    
    # function to calculate the execution time
    def time(label)
      t1 = Time.now
      #yield.tap{ puts "%s: %.1fs" % [ label, Time.now-t1 ] }
      yield.tap{ Laclasse::Log.info("%s: %.1fs" % [ label, Time.now-t1 ]) }
    end
    #--------------------------------------------------------------------#
    
    def is_complet?
      @is_complet
    end
    
    def is_delta?
      @is_delta
    end

    def get_file_date(filename)
      splited_name = filename.split('_')
      if splited_name.length > 3
        return Date.parse(splited_name[3])
      else
        return nil
      end
    end

    def etb_file_list(code_uai)
      @etb_file_map[code_uai]
    end

  end
end