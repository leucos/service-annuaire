#coding: utf-8
module Sequel
  module Plugins
    # Tentative de faire simplement de la recherche multi champs sur un model Sequel
    module SelectJsonArray

      # Simple class qui va contenir tous les champs JSON d'un dataset
      # sur lequel on a fait select_json_array!
      # Et qui va automatiquement parsé la chaîne JSON lors du each
      class JsonParseRowProc
        def initialize
          @fields_to_parse = []
        end

        def add_field(field)
          @fields_to_parse.push(field)
        end

        def call(values)
          values.each do |k, v|
            values[k] = JSON.parse(v) if @fields_to_parse.include?(k) and v
          end
        end
      end

      module DatasetMethods
        def naked!
          self.row_proc.is_a?(JsonParseRowProc) ? self : super
        end

        def naked
          self.row_proc.is_a?(JsonParseRowProc) ? self : super
        end
        # Rajoute une fonction select_json_array au model et au dataset
        # Qui permet de renvoyé dans une seul requète un ensemble de donnée formatté en JSON
        # ex : la liste des numéro de téléphone d'un utilisateur renvoyé dans une seule ligne avec
        # les autres attributs de l'utilisateur
        # param name String nom du champs renvoyé par la requète 
        # param attributes_hash Hash<Symbole, String>
        # clé : symbole Sequel du champs sql (ex : :telephone__numero)
        # valeur : nom de l'attribut json (ex : "numero"), si précédé par un i_ cela signifie que c'est un nombre
        # et que le résultat JSON n'aura pas de double quotes
        # ATTENTION : Cette fonction utilise la fonction MySql GROUP_CONCAT et n'est donc pas compatible
        # avec une autre base de données 
        # Cette fonction redéfinie aussi le row_proc du dataset pour que le JSON soit automatiquement
        # parsé lors d'un each ou autre
        # Le dataset n'est donc plus un dataset de Model mais un dataset simple (comme "naked" mais avec mon row_proc)
        def select_json_array!(name, attributes_hash)
          raw_sql = "CONCAT('[',GROUP_CONCAT(DISTINCT "

          i = 0
          attributes_hash.each do |sql_symbol, json_attribut|
            raw_sql += "," if i != 0
            raw_sql += "CONCAT("
            raw_sql += i == 0 ? "'{" : "',"
            close_obj = i == attributes_hash.count - 1 ? '}' : ''

            is_number = json_attribut[0..1] == "i_"
            if is_number
              json_attribut = json_attribut[2..-1]
              raw_sql += "\"#{json_attribut}\":',#{DB.literal(sql_symbol)},'#{close_obj}')"
            else
              raw_sql += "\"#{json_attribut}\":\"',#{DB.literal(sql_symbol)},'\"#{close_obj}')"
            end
            i += 1
          end

          raw_sql += "),']') AS #{name}"

          dataset = self.select_more(raw_sql.lit)
          
          dataset.row_proc = JsonParseRowProc.new unless dataset.row_proc.is_a?(JsonParseRowProc)
          dataset.row_proc.add_field(name)

          return dataset
        end
      end

      module ClassMethods
        def select_json_array!(name, attributes_hash)
          self.dataset.select_json_array(name, attributes_hash)
        end
      end
    end
  end
end