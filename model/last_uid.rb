#coding: utf-8
#
# model for 'last_uid' table
# generated 2012-10-31 10:03:57 +0100 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# last_uid                      | char(8)             | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
# 
# Génération des UID de la forme Vxx6iiii
# 
#  Cette génération fonctionne comme les immatriculations. Les lettres V et 6 nous sont imposées
#  On commence par VAA60000 et on incrémente le nombre. Une fois à VAA69999, on passe à VAB60000
#  et ainsi de suite.

#  get_next_uid sauvegarde automatiquement le nouvel uid généré dans la table last_uid
#
# Structure de données
#    Table last_uid : enregistre le dernier UID généré et lors du next met tout de suite à jour
#    (au sein d'une opération lock tables mysql) le nouvel uid généré. C'est un système qui rend possible
#    les accès concurrentiel à la création d'uid. Un peu comme auto incremente mais avec des id non numeric
#
# Usage : @newuid = LastUid.get_next_uid()
# L'usage le plus fréquent est lors de la création d'un utilisateur 
# un before_create hook appel get_next_uid() lors d'un User.create()
#
class LastUid < Sequel::Model(:last_uid)
  # Calcul l'uid suivant et le sauvegarde dans la table last_uid
  # afin de garantir l'unicité des id lors d'accès concurrentiels
  # Attention : Cette fonction gère l'unicité des uid dans l'ent.
  # Il y en a environ 7 millions disponibles, c'est beaucoup mais pas trop.
  # Veillez à savoir ce que vous faites quand vous appelez cette fonction !!!
  def self.get_next_uid ()
    last_uid = LastUid.first ? LastUid.first.last_uid : nil
    next_uid = increment_uid(last_uid)
    if last_uid
      LastUid.update(:last_uid => next_uid)
    else
      LastUid.create(:last_uid => next_uid)
    end
    return next_uid
  end

  # Fait l'incrementation suivant la méthode des plaques d'immatriculation
  # sans rien sauvegarder dans la base de données
  def self.increment_uid(current_uid)

    return "#{LETTRE_PROJET_LACLASSE}AA#{CHIFFR_PROJET_LACLASSE}0000" if current_uid.nil?

    alphabet = ('A'..'Z').to_a
    change_lettre = [false, false]
    
    current_num = current_uid[4,4].to_i
    # Attention on incremente de droite à gauche
    current_char = [current_uid[2], current_uid[1]]
    next_char = [current_uid[2], current_uid[1]]

    # Incrémenter le nombre
    next_num = ((current_num + 1)%10000).to_s.rjust(4, '0')
    change_lettre[0] = (current_num == 9999)
    
    2.times do |i|
      if change_lettre[i]
        if current_char[i] != 'Z'
          next_char[i] = alphabet[(alphabet.index(current_char[i]) + 1)]
        elsif i == 0
          change_lettre[i+1] = true
          next_char[i] = 'A'
        else
          raise "BIG PROBLEME : PLUS D'UID DISPONIBLE!! MODIFICATION DU SDET NECESSAIRE!!!"
        end
      end
    end

    "#{LETTRE_PROJET_LACLASSE}#{next_char[1]}#{next_char[0]}#{CHIFFR_PROJET_LACLASSE}#{next_num}"
  end
end
