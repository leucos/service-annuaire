#coding: utf-8
#
# model for 'profil_user' table
# generated 2012-10-26 17:22:55 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# profil_id                     | char(4)             | false    | PRI      |            | 
# user_id                       | char(16)            | false    | PRI      |            | 
# etablissement_id              | int(11)             | false    | PRI      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class ProfilUser < Sequel::Model(:profil_user)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  unrestrict_primary_key()

  # Referential integrity
  #one_to_many  :profil_user_has_fonction, :key=>:profil_id, :key=>:user_id, :key=>:etablissement_id
  many_to_one  :profil_national
  many_to_one  :user
  many_to_one  :etablissement
  many_to_many :fonction, :left_key=>[:profil_id, :user_id,:etablissement_id], :right_key=>:code_men,
    :join_table=>:profil_user_has_fonction
  #one_to_many :profil_user_has_fonction
  # def self.eleves
  #   filter(:profil_id == "ELV")
  # end


  # Not nullable cols and unicity validation
  def validate
    super
  end
end
