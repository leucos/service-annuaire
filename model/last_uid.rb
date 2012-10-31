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
  # Vueillez à savoir ce que vous faites quand vous appelez cette fonction !!!
  def self.get_next_uid ()
    #Très important on se met en mode transaction pour s'assurer que 2 mêmes
    #uid ne seront pas générés
    uid = nil
    #alphabet = ('A'..'Z').to_a
    #change_lettre1 = false
    #change_lettre2 = false
    
    # UTILISE LE LOCK MYSQL
    DB.run("LOCK TABLES last_uid WRITE;")

    # lecture des paramètres
    lastuid = DB[:last_uid].first
    if lastuid.nil?
      # Si on a pas encore d'uid, créer le premier
      uid = "#{LETTRE_PROJET_LACLASSE}AA#{CHIFFR_PROJET_LACLASSE}0000"
      DB[:last_uid].insert(:last_uid => uid)
    else

      #Sinon, trouve le prochain en suivant une règle similaire à celle
      #des plaques d'immatriculation de voiture
      lastuid = lastuid[:last_uid]
      
      # increment the id by 1 
      uid = increment_uid(lastuid)
      # Sauvegarde du dernier UID générer
      DB[:last_uid].update(:last_uid => uid)
    end

    #Ne pas oublier le unlock
    DB.run("UNLOCK TABLES;")

    return uid
  end

  # Fait l'incrementation suivant la méthode des plaques d'immatriculation
  # sans rien sauvegarder dans la base de données
  def self.increment_uid(lastuid)
    
    uid = nil
    alphabet = ('A'..'Z').to_a
    change_lettre1 = false
    change_lettre2 = false
    
    curnum = lastuid[4,4].to_i
    curchr1 = lastuid[1]
    curchr2 = lastuid[2]

      # Incrémenter le nombre
    if curnum < 9999
      nb = curnum + 1
    else
      change_lettre2 = true
      nb = 0
    end
    curnum = nb.to_s.rjust(4, '0')

    # Changer la lettre 2 si besoin
    if  change_lettre2
      if curchr2 != "Z"
        curchr2 = alphabet[(alphabet.index(curchr2) + 1)]
      else
        change_lettre1 = true
        curchr2 = "A"
      end
    end

    # Changer la lettre 1 si besoin
    if change_lettre1
      if curchr1 != "Z"
        curchr1 = alphabet[(alphabet.index(curchr1) + 1)]
      else
        raise "BIG PROBLEME : PLUS D'UID DISPONIBLE!! MODIFICATION DU SDET NECESSAIRE!!!"
      end
    end

    uid = LETTRE_PROJET_LACLASSE + curchr1 + curchr2 + CHIFFR_PROJET_LACLASSE + curnum
    return uid
  end
end
