#coding: utf-8
module Alimentation
  #Très simple classe qui représente une base de données relationnelle stockée en mémoire
  #sous forme de Hash
  #key : nom de la table, value : Array (MemoryTable) des enregistrements créés (représentés sous forme de Hash)
  class MemoryDb < Hash
    #A la création, on passe un Array contenant toutes les tables présentent dans la BDD
    #De cette manière, on peut créer les Array de stockage pour chacune de ces tables
    def initialize(table_list)
      super()
      #On créer des tableaux pour chacune des clés
      table_list.each do |t|
       store(t, MemoryTable.new)
      end
    end
  end

  #Petite surcharge des Array qui permet la recherche et l'ajout d'éléments
  #via des Hash représentants des enregistrements de BDD
  #Les objects ne sont pas référencés par des ID (il peu y en a avoir tout de même) mais simplement
  #par des références.
  #Ex la table membre_regroupement n'a pas user_id et regroupement_id comme membre, mais user (qui a peut-etre un id)
  #et regroupement (qui a aussi peut-etre un id)
  #Cette classe fournit des fonctionnalités de requetage très sommaires
  class MemoryTable < Array
    #Find an already parsed model with a very simple search on all the columns
    # in condition_map
    #Can be unique (return a Hash) or multiple (return an Array of Hash)
    def find(condition_map, multiple=false)
      result = nil
      each do |d|
        equal = false
        condition_map.each do |k, v|
          #Si la clé est un array
          if k.kind_of?(Array)
            #C'est qu'on fait une requète sur une donnée complexe
            #le premier élément est le nom de la clé et le deuxième est le nom de la clé dans la donnée
            #Ex: je veux trouver dans profil_user tous les utilisateur avec id_jointure_aaf == 1234
            #Je ne peux pas faire find({:user => 1234}) car user est un type complexe
            # ni find({:user => {id_jointure_aaf == 1234}}) car il n'y a pas que id_jointure_aaf dans user
            #donc je dois faire : find({[:user, :id_jointure_aaf] => 1234})
            equal = d[k[0]][k[1]] == v
          else
            equal = d[k] == v
          end
          break unless equal
        end
        if equal
          if multiple
            result = [] if result.nil?
            result.push(d)
          else
            return d
          end
        end
      end

      return result
    end

    # Alias pour find(condition, true)
    def filter(condition_map)
      find(condition_map, true)
    end

    #condition_map : Hash des données recherchées
    #data : Hash des données à rajouté. Si nil alors data et condition_map égal.
    #return : soit la donnée passée en paramètre, soit la donnée trouvée
    def find_or_add(condition_map, data=nil)
      data = condition_map if data.nil?
      existing_data = find(condition_map)
      if existing_data.nil?
        push(data)
      else
        data = existing_data
      end
      return data
    end
  end
end