#!ruby
#coding: utf-8
require 'zlib'
require 'archive/tar/minitar'

require __DIR__('parser_xml_menesr')
require __DIR__('diff_generator')
require __DIR__('diff_view')
require __DIR__('db_sync')

#Super classe qui prend un fichier targz (complet ou delta) de l'académie et alimente automatiquement
#Tous les établissements présents dans l'archive
module Alimentation
  class Alimentor
    attr_accessor :etb_file_map, :archive_name, :date_alim, 
    #Attribut présent dans le nom des fichiers
    @@complet_name = "Complet"
    @@delta_name = "Delta"

    def initialize(archive_name)
      @archive_name = archive_name
      @is_complet = File.basename(@archive_name).index(@@complet_name) != nil
      #key : code UIA de l'établissement, value: Array de fichiers d'alimentation de l'établissement
      @etb_file_map = Hash.new
      name_split = File.basename(@archive_name).split(".")
      @date_alim = Date.parse(name_split[1]) if name_split.length > 1
      @temp_dir = "tmp"
    end

    def clean_tmp_dir
      if Dir.exists?(@temp_dir)
        Dir.foreach(@temp_dir) do |f|
          File.delete(File.join(@temp_dir,f)) if File.file?(File.join(@temp_dir,f))
        end
      end
    end

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

    #(v2) list files by categorie
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

    def prepare_alimentation
      Laclasse::Log.info("prepare_alimentation")
      ok = unpack_archive()
      list_all_etb() if ok

      return @etb_file_map.length > 0
    end

    # (v2) of prepare_alimentation because files are anonymous 
    def prepare_data 
      Laclasse::Log.info("prepare data")
      start = Time.now
      ok = unpack_archive()
      list_all_files if ok 
      fin = Time.now
      Laclasse::Log.info("folder contains #{@etb_file_map.length} categories")
      @etb_file_map.each do |categorie, list|
        Laclasse::Log.info("#{categorie} contains #{list.length} files")
      end 
      Laclasse::Log.info("prepering data took #{fin-start} seconds")
      return @etb_file_map.length > 0
    end 

    #Parse l'ensemble des fichiers pour lequels l'id d'établissement existe déjà dans l'annuaire
    def parse_all_etb
      @etb_file_map.each do |uai, file_list|
        begin
          Laclasse::Log.info("Start parsing etablissement #{uai}")
          # i think we need to develop a generic parser XML, CSV, Oracle
          #parser = Parser.new
          # for the moment we use xml parser
          parser = ParserXmlMenesr.new
          cur_etb_data = parser.parse_etb(uai, file_list)
          #Laclasse::Log.debug("memory DB data"+cur_etb_data.inspect)
          unless cur_etb_data.nil?
            Laclasse::Log.info("Generate diff")
            diff_generator = DiffGenerator.new(uai, cur_etb_data, @is_complet)
            diff = diff_generator.generate_diff_etb()

            #puts diff

            ##Laclasse::Log.info("Generate diff_view")
            ##diff_view = DiffView.new
            ##diff_view.generate_html(uai, diff, @date_alim, @is_complet)

            Laclasse::Log.info("Synchronize DB")
            ##sync = DbSync.new
            ##sync.sync_db(diff)
          end
        rescue => e
          puts "Erreur lors de l'alimentation de l'établissement #{uai}"
          puts "#{e.message}"
          puts "#{e.backtrace}"
        end
      end
    end

    # (v2) parse_data 
    # instead of parsing files by (etablissement_id ), parse_data parses files by category
    # categories include Eleve, EtabEducNat, MatiereEducNat, MefEducNat, PersEducNat, PersRelEleve
    # Parsing data must start with EtabEducNat because it is independant of other info 
    # options only parsing and save in memory
    # parsing and synchronizing 
    # parsing, synchronizing and diff generating
    def parse_data(options={})
      start_categorie = 'EtabEducNat'
      cur_etb_data = parse_categorie(start_categorie)
      parse_categorie('Eleve')
      #manque the synchronizing
      @etb_file_map.each do |categorie, file_list|
        begin
          next if (categorie == start_categorie or categorie == "Eleve")
          Laclasse::Log.info("Start parsing categorie #{categorie}")
          # i think we need to develop a generic parser XML, CSV, Oracle
          #parser = Parser.new
          # for the moment we use xml parser
          parser = ParserXmlMenesr.new
          cur_etb_data = parser.parse_categorie(categorie, file_list)
          #Laclasse::Log.debug("memory DB data"+cur_etb_data.inspect)
          if !cur_etb_data.nil? && options["PARSE_DIFF_SYNC"] = true
            Laclasse::Log.info("Generate diff")
            diff_generator = DiffGenerator.new(uai, cur_etb_data, @is_complet)
            diff = diff_generator.generate_diff_etb()

            Laclasse::Log.info("Generate diff_view")
            diff_view = DiffView.new
            diff_view.generate_html(uai, diff, @date_alim, @is_complet)

            Laclasse::Log.info("Synchronize DB")
            sync = DbSync.new
            sync.sync_db(diff)
          end
        rescue => e
          #puts "Erreur lors de l'alimentation de l'établissement #{uai}"
          puts "#{e.message}"
          puts "#{e.backtrace}"
        end
      end
    end

    # (v2) parse categorie (etablissements, eleves, ...)
    def parse_categorie(categorie)
      if !@etb_file_map[categorie].nil?
        start = Time.now
        Laclasse::Log.info("Start parsing categorie #{categorie}")
        # i think we need to develop a generic parser XML, CSV, Oracle
        #parser = Parser.new
        # for the moment we use xml parser
        Laclasse::Log.info("#{categorie} contains #{@etb_file_map[categorie].length} file")
        parser = ParserXmlMenesr.new
        cur_etb_data = parser.parse_categorie(categorie, @etb_file_map[categorie])
        fin = Time.now 
        Laclasse::Log.info("parsing categorie #{categorie} took #{fin-start} seconds")
      else 
        Laclasse::Log.error("Categorie #{categorie} does not exist")
      end
      return cur_etb_data
    end 

    def is_complet?
      @is_complet
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