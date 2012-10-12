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
    attr_accessor :etb_file_map, :date_alim
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
        Ramaze::Log.info("#{@archive_name} is good")
        Archive::Tar::Minitar.unpack(tgz, @temp_dir)
      end

      ok = Dir.exists?(@temp_dir)
      Ramaze::Log.error("Temp dir not created abording alimentation") unless ok
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

    def prepare_alimentation
      Ramaze::Log.info("prepare_alimentation")
      ok = unpack_archive()
      list_all_etb() if ok

      return @etb_file_map.length > 0
    end

    #Parse l'ensemble des fichiers pour lequels l'id d'établissement existe déjà dans l'annuaire
    def parse_all_etb
      @etb_file_map.each do |uai, file_list|
        begin
          Ramaze::Log.info("Start parsing etablissement #{uai}")
          parser = Parser.new
          cur_etb_data = parser.parse_etb(uai, file_list)
          unless cur_etb_data.nil?
            Ramaze::Log.info("Generate diff")
            diff_generator = DiffGenerator.new
            diff = diff_generator.generate_diff_etb(uai, cur_etb_data, @is_complet)

            Ramaze::Log.info("Generate diff_view")
            diff_view = DiffView.new
            diff_view.generate_html(uai, diff, @date_alim, @is_complet)

            Ramaze::Log.info("Synchronize DB")
            sync = DbSync.new
            sync.sync_db(diff)
          end
        rescue => e
          puts "Erreur lors de l'alimentation de l'établissement #{uai}"
          puts "#{e.message}"
          puts "#{e.backtrace}"
        end
      end
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