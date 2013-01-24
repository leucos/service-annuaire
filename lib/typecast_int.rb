#coding: utf-8
module Sequel
  module Plugins
    # Mini plugin Sequel qui rajoute le plugin type_cast_on_load
    # et en même temps définit le type de la colonne comme integer.
    # Nécessaire pour les tables ORACLE qui ont mal été définies
    module TypecastInt
      def self.apply(model, *columns)
        # On precise a Sequel que la colonne est de type integer
        # Si il y a un "_" avant le nom, cela signifie qu'on ne doit pas mettre en integer
        columns.each {|c| model.db_schema[c][:type] = :integer unless c.to_s[0] == '_'}
        # On enlève les potentiels "_"
        columns.map! do |c|
          if c.to_s[0] == '_'
            c.to_s[1..-1].to_sym
          else
            c
          end
        end
        model.plugin :typecast_on_load, *columns
      end
    end
  end
end