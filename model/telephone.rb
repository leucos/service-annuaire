#coding: utf-8
#
# model for 'telephone' table
# generated 2012-04-25 15:54:20 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# numero                        | char(32)            | false    |          |            | 
# user_id                       | char(8)             | false    | MUL      |            | 
# type_telephone_id             | char(8)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Telephone < Sequel::Model(:telephone)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :user
  many_to_one :type_telephone

  def before_validation
    # Il peut y avoir des espaces et des tirets
    self.numero.gsub!(' ', '')
    self.numero.gsub!('-', '')
  end

  def before_create
    # On ne détecte le téléphone portable que si on a le type par défaut
    pref = self.numero[0,2]
    pref_int = self.numero[0,5]
    if self.type_telephone_id == TYP_TEL_MAIS and (pref == "06" or pref_int == "+336" or pref == "07" or pref_int == "+337")
      self.type_telephone_id = TYP_TEL_PORT
    end
  end

  # Not nullable cols
  def validate
    super
    validates_presence [:type_telephone_id, :user_id, :numero]
    # Un numéro peut-être composé d'un '+' au début et suivi de 10 à 13 chiffres
    validates_format /^[\+|\d]\d{9,13}$/, :numero
  end
end
