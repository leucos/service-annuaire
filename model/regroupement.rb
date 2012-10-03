#coding: utf-8
#
# model for 'regroupement' table
# generated 2012-04-19 17:45:32 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# libelle                       | varchar(45)         | true     |          |            | 
# niveau_id                     | int(11)             | true     | MUL      |            | 
# etablissement_id              | char(8)             | false    | MUL      |            | 
# code_mef_aaf                  | int(11)             | true     |          |            | 
# date_last_maj_aaf             | date                | true     |          |            | 
# libelle_aaf                   | char(8)             | true     |          |            | 
# type_regroupement_id          | int(11)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Regroupement < Sequel::Model(:regroupement)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  one_to_many :enseigne_regroupement
  one_to_many :membre_regroupement
  many_to_one :etablissement

  # Not nullable cols
  def validate
    super
    validates_presence [:type_regroupement_id]
  end

  #Les regroupement de type classe ont forcément un niveau
  def niveau
    Niveau[niveau_id]
  end

  def nb_membres
    MembreRegroupement.filter(:regroupement => self).count
  end

  def is_classe
    type_regroupement_id == 'CLS'
  end

  def is_groupe
    type_regroupement_id == 'GRP'
  end

  # returns the number of groups in the class 
  def nb_groups
    if type_regroupement_id == 'CLS'
      MembreRegroupement.filter(:user_id => MembreRegroupement.select(:user_id).filter(:regroupement => self)).select(:regroupement_id).distinct.count
    else
      raise 'Erreur, le groupe n\' est pas une classe'
    end
  end

  # Liste des membres du regroupement dont le profil est élève
  def eleves
    User.filter(:membre_regroupement => MembreRegroupement.filter(:regroupement => self),
      :profil_user => ProfilUser.filter(:etablissement_id => etablissement_id, :profil_id => 'ELV')).all
  end

  # Liste des membres du regroupement dont le profil est Prof
  def profs
    User.filter(:enseigne_regroupement => EnseigneRegroupement.filter(:regroupement => self),
      :profil_user => ProfilUser.filter(:etablissement_id => etablissement_id, :profil_id => 'ENS')).all  
  end

  def membres
    User.filter(:membre_regroupement => MembreRegroupement.filter(:regroupement => self),
      :profil_user => ProfilUser.filter(:etablissement_id => etablissement_id)).all 
  end

  def add_membre(user_id)
    membre = MembreRegroupement.new
    membre.regroupement = self
    membre.user_id = user_id
    membre.save
    #MembreRegroupement.create(:regroupement => self, :user_id => user_id)
  end
  def delete_membre(user_id)
    MembreRegroupement.where(:user_id => user_id, :regroupement => self).delete
  end

  def add_prof(user_id)
    #actually sans matieres
    prof = EnseigneRegroupement.new
    prof.regroupement = self
    prof.user_id = user_id
    prof.matiere_enseignee_id = 100
    prof.save 
  end

  def delete_prof(user_id)
    EnseigneRegroupement.where(:user_id => user_id, :regroupement => self).delete
  end
end
