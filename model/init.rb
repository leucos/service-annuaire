#coding: utf-8
#
# include file to access all models
# generated 2012-05-21 18:00:26 +0200 by model_generator.rb
#
Sequel.extension(:pagination)

# MODELS
# ATTENTION SERVICE DOIT POUVOIR ETRE ACCESSIBLE PAR TOUS LES AUTRES MODELS
require_relative 'service'
require_relative 'activite'
require_relative 'activite_role'
require_relative 'application'
require_relative 'application_etablissement'
require_relative 'enseigne_regroupement'
require_relative 'etablissement'
require_relative 'famille_matiere'
require_relative 'fonction'
require_relative 'last_uid'
require_relative 'matiere_enseignee'
require_relative 'niveau'
require_relative 'param_application'
require_relative 'param_etablissement'
require_relative 'param_user'
require_relative 'profil'
require_relative 'profil_user'
require_relative 'regroupement'
require_relative 'relation_eleve'
require_relative 'ressource'
require_relative 'role'
require_relative 'role_user'
require_relative 'telephone'
require_relative 'type_etablissement'
require_relative 'type_param'
require_relative 'type_regroupement'
require_relative 'type_relation_eleve'
require_relative 'type_telephone'
require_relative 'user'
require_relative 'email'
require_relative 'eleve_regroupement'

#On fait manuellement l'association table=>model car elle est impossible a faire automatiquement
#(pas de lien 1<=>1 entre dataset et model stackoverflow 9408785)
MODEL_MAP = {}
DB.tables.each do |table|
  capitalize_name = table.to_s.split(/[^a-z0-9]/i).map{|w| w.capitalize}.join
  begin
    MODEL_MAP[table] = Kernel.const_get(capitalize_name)
  rescue => e
    puts e.message
  end
end