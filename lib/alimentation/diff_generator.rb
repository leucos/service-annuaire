#!ruby
#coding: utf-8
module Alimentation
  # Classe d'erreur quand on a une donnée d'update qui n'a pas les mêmes id
  class MismatchUpdateIdError < StandardError
  end
  # raisé quand on essait de créer une donnée d'update sans données provenant de la base
  class NoDbEntryError < StandardError
  end
  # Quand on utilise une table inexistante
  class WrongTableError <  StandardError
  end

  class NoIdError < StandardError
  end

  class DiffGenerator

    def initialize(uai, etb_data, is_complet)
      @is_complet = is_complet
      @cur_etb_uai = uai
      @cur_etb_data = etb_data
      init_diff_array()
      @removed_elv_list = []
    end

    def init_diff_array
      @cur_etb_diff = {}
      @cur_etb_data.each_key do |table|
        #Sur chaque table, il y a ces 3 opérations possibles
        #Et on va stocker toutes les infos nécessaires pour les réaliser
        #Ensuite on pourra aisément réaliser un fichier de diff et/ou mettre à jour la BDD
        @cur_etb_diff[table] = {create: [], update: [], delete: []}
      end
    end

    def find_available_login(user)
      # Construction du login par défaut
      login = User.get_default_login(user[:prenom], user[:nom])
      #Si homonymes, on utilise des numéros à la fin
      login_number = 1
      final_login = login
      # Ensuite on s'assure que le login n'est pas présent dans la BDD
      # Ou dans les utilisateurs en train d'être créés
      # Si c'est le cas, on incrémente le nombre
      while !User.is_login_available(final_login) or !@cur_etb_data[:user].find({:login => final_login}).nil?
        final_login = "#{login}#{login_number}"
        login_number += 1
      end

      return final_login
    end

    #Check tous les champs de la données pour voir s'il diffèrent
    #avec la donnée en mémoire et supprime toutes les colonnes identiques
    #Afin de faire un update que sur ce qui change
    #return : true if there is still data to update
    def clean_data_to_update(data, db_entry, id_fields)
      #On ne supprime pas les champs d'identifiant car on en a de toute façon
      #besoin pour faire l'update
      id_fields.each {|id| raise NoIdError.new unless data.keys.sort.include?(id)}
      data.delete_if do |k, v|
        # On ne peut pas accepter des id différents
        raise MismatchUpdateIdError.new if id_fields.include?(k) and v != db_entry[k]
        !id_fields.include?(k) and v == db_entry[k]
      end

      #S'il ne reste plus que les clé primaires dans les données c'est qu'il n'y a plus rien a updater
      return data.keys.sort != id_fields.sort
    end

    def add_data(table_name, mode, data, db_entry=nil)
      raise WrongTableError.new("#{table_name} inexistante") if @cur_etb_diff[table_name].nil?

      table_operation = @cur_etb_diff[table_name][mode]

      if mode == :update
        raise NoDbEntryError.new("Update without db_entry") if db_entry.nil?
        # On stocke aussi les données actuelles pour générer des diffs plus complets
        # ex : Rene renommé en René
        to_add = {current: db_entry, updated: data}
      else
        to_add = data
      end

      # On s'assurce que les données ne sont pas déjà présentent
      # ex : d'une relation élève qui peut se trouver 2 fois supprimé car on passe 2 fois
      # dans le traitement
      unless table_operation.include?(to_add)
        table_operation.push(to_add)
      end
    end
    
    # S'assure que les données ont vraiment besoin d'être mise à jour
    # avant de les rajouter
    def add_data_to_update(table_name, data, db_entry, id_fields = [:id])
      need_update = clean_data_to_update(data, db_entry, id_fields)
      if need_update
        add_data(table_name, :update, data, db_entry)
      end
    end

    def add_data_to_create(table_name, data)
      add_data(table_name, :create, data)
    end

    def add_data_to_delete(table_name, data)
      add_data(table_name, :delete, data)
    end

    def diff_etablissement(etab)
      # create : quand l'uia n'existe pas
      # update : quand des données sont MAJ
      # delete : PAS DE DELETE
      db_entry = Etablissement[:code_uai => etab[:code_uai]]
      if db_entry.nil?
        add_data_to_create(:etablissement, etab)
      else
        etab[:id] = db_entry.id
        # On veut que le code_uai reste pour que les requètes se passent bien
        add_data_to_update(:etablissement, etab, db_entry, [:id, :code_uai])
      end
    end

    def diff_user(user)
      # - Table :user
      # create : quand on trouve un nouvel id de jointure
      #   ET qu'on est pas arrivé à faire un recollement utilisateur.
      # update : mise à jour des données ou recollement utilisateur.
      # delete : PAS DE DELETE
      db_entry = DB[:user].filter(:id_jointure_aaf => user[:id_jointure_aaf]).first
      if db_entry.nil?
        #On essait de faire un recollement
        #todo ne pas prendre en compte les accents
        req = User.
          filter(:nom.ilike(user[:nom]), :prenom.ilike(user[:prenom]),
          :sexe => user[:sexe], :date_naissance => user[:date_naissance],
          :id_jointure_aaf => nil, :profil_user => ProfilUser.filter(:etablissement => Etablissement.filter(:code_uai => @cur_etb_uai)))
        db_entry = req.first.to_hash if req.count == 1
      end

      #Il s'agit bien d'une création
      if db_entry.nil?
        add_data_to_create(:user, user)
        #On lui créer un login/mot de passe par défaut de type 1ere lettre prenom + nom
        #Si deja existant on essait avec 2 lettres du prenom ainsi de suite
        user[:login] = find_available_login(user)
        #todo : générer un autre mot de passe ?
        user[:password] = user[:login]
      else
        #Important, on set l'id ent de l'utilisateur. Comme ça on pourra aussi retrouver les données
        # reliées à lui.
        user[:id] = db_entry[:id]
        #Petit hack, je met date_last_maj_aaf comme un id car il change à chaque fois
        #Et que si y a que ça qui change c'est pas grave...
        add_data_to_update(:user, user, db_entry, [:id, :date_last_maj_aaf])
      end
    end

    def diff_profil_user(profil_user)
      # - Table :profil_user
      # create : nouveau ratachement
      # update : changement de profil (spécifique au pen),
      #Si l'utilisateur, n'a pas d'id, c'est forcément un nouveau rattachement
      user_id = profil_user[:user][:id]
      # puts "Etab=#{profil_user[:etablissement]}"
      if user_id.nil?
        #Le premier profil est par défaut actif
        profil_user[:actif] = true
        add_data_to_create(:profil_user, profil_user)
      else
        db_entry = ProfilUser.filter(:user_id => user_id,
          :etablissement => Etablissement.
            filter(:code_uai => profil_user[:etablissement][:code_uai])).first
        #Et Si le rattachement existe pas on créé
        if db_entry.nil?
          #Le premier profil est par défaut actif
          #todo : attention a pas avoir plusieurs profil actifs !!!
          # puts "Etablissement=#{Etablissement.
          #   filter(:code_uai => profil_user[:etablissement][:code_uai])}"
          # puts "Create d'un profil_user (#{ProfilUser.filter(:user_id => user_id).count} profils existants) pour #{profil_user[:user][:nom]} #{profil_user[:user][:prenom]} id=#{profil_user[:user][:id_jointure_aaf]}"
          profil_user[:actif] = true
          add_data_to_create(:profil_user, profil_user)
        #Sinon on update
        else
          add_data_to_update(:profil_user, profil_user, db_entry.to_hash, [:user, :etablissement])
        end
      end
    end

    def remove_from_regroupement(user_id, table_name)
      etb = Etablissement[:code_uai => @cur_etb_uai]
      if etb
        req = DB[table_name].
                join(:regroupement, :id => :regroupement_id).
                filter(:etablissement_id => etb.id, :user_id => user_id).
                select(:user_id, :regroupement_id)
        req.each do |membre|
          add_data_to_delete(table_name, membre)
        end
      end
    end

    def remove_from_etb(profil)
      add_data_to_delete(:profil_user, profil)
      #On supprime aussi les différents rattachements que la personne avait dans l'établissement
      remove_from_regroupement(profil[:user_id], :membre_regroupement)
      remove_from_regroupement(profil[:user_id], :enseigne_regroupement)

      #Et si l'utilisateur est un élève et que ses parents n'ont pas d'autres
      #enfants dans l'établissement. Alors on supprime aussi le profil parent
      if profil[:profil_id] == 'ELV'
        @removed_elv_list.push(profil)
      end
    end

    def get_parent_etb_children(parent_id)
      etb = Etablissement[:code_uai => @cur_etb_uai]
      if etb
        return DB[:relation_eleve].
          join(:user, :id => :eleve_id).
          join(:profil_user, :profil_user__user_id => :user__id).
          filter(:etablissement_id => etb.id).
          filter(:relation_eleve__user_id => parent_id).
          select(:eleve_id).all
      else
        return []
      end
    end

    def remove_deleted_elv_parents()
      deleted_parent = []
      etb = Etablissement[:code_uai => @cur_etb_uai]
      @removed_elv_list.each do |elv|
        #On récupère la liste des responsable d'un elève
        resp_elv_list = DB[:relation_eleve].
          join(:user, :id => :eleve_id).
          join(:profil_user, :profil_user__user_id => :user__id).
          filter(:user__id => elv[:user_id]).
          select(:relation_eleve__user_id).all

        resp_elv_list.each do |resp|
          #Puis la liste de tous les elèves dont le parent est responsable
          elv_resp_list = get_parent_etb_children(resp[:user_id])
          nb_deleted_elv_resp = 0
          elv_resp_list.each do |elv_resp|
            @removed_elv_list.each do |del_elv|
              if del_elv[:user_id] == elv_resp[:eleve_id]
                nb_deleted_elv_resp += 1
                break
              end
            end
          end

          #Si tous les élèves se trouvent dans la listes des élèves supprimé
          #Bah ca veut dire qu'on peut aussi supprimer les parents
          if nb_deleted_elv_resp == elv_resp_list.length and etb
            #Formattage de la donnée pour être supprimé
            to_delete = {user_id: resp[:user_id], etablissement_id: etb.id, profil_id: 'PAR'}
            #Attention à ne pas les supprimer 2 fois tout de même
            unless deleted_parent.include?(to_delete)
              remove_from_etb(to_delete)
            end
          end
        end
      end
    end

    def remove_deleted_relation_parents()
      deleted_parent = []
      etb = Etablissement[:code_uai => @cur_etb_uai]
      #Il faut supprimer le parent de l'établissement quand il n'est plus dans une relation d'élève
      #Donc regarder pour chaque relation_eleve supprimé si le compte à un profil_utilisateur
      @cur_etb_diff[:relation_eleve][:delete].each do |rel|
        parent_profil = ProfilUser[
          :user_id => rel[:user_id], 
          :etablissement => Etablissement.filter(:code_uai => @cur_etb_uai), 
          :profil_id => "PAR"
        ]
        unless  parent_profil.nil?
          parent_profil = parent_profil.to_hash
          #Et que le parent n'est pas présent dans l'alimentation (relation_eleve) et qu'il n'a pas d'autres enfants
          #en BDD que ceux supprimés dans la MAJ alors on supprime le parent de l'établissement
          rel_data = @cur_etb_data[:relation_eleve].find({[:user, :id] => parent_profil[:user_id]})

          parent_children = @cur_etb_diff[:relation_eleve][:delete].reject {|r| r[:user_id] != rel[:user_id]}
          parent_children.map! {|c| {:eleve_id => c[:eleve_id]} }
          etb_children = get_parent_etb_children(rel[:user_id])
          if parent_children.sort == etb_children.sort and etb
            to_delete = {user_id: rel[:user_id], etablissement_id: etb.id, profil_id: 'PAR'}
            unless deleted_parent.include?(to_delete)
              #puts "Suppression de la maman!!"
              remove_from_etb(to_delete)
            end
          end
        end
      end
    end

    def diff_delete_user
      # delete : deleteRequest dans un delta  ou user avec id de jointure plus présent dans un complet
      #todo gérer les deleteRequest dans les delta
      if @is_complet
        req = ProfilUser.
          filter(:etablissement => Etablissement.filter(:code_uai => @cur_etb_uai)).
          exclude(:user => User.filter(:id_jointure_aaf=>nil)).
          select(:etablissement_id, :user_id, :profil_id)
        req.each do |profil|
          profil = profil.to_hash
          parsed_user = @cur_etb_data[:profil_user].find({[:user, :id] => profil[:user_id]})
          if parsed_user.nil?
            remove_from_etb(profil)
          end
        end
      else
        #gestion des deletes dans les delta
        #On recupère tous les users avec un flag deleted
        deleted_user_list = @cur_etb_data[:user].find({:deleted => true}, true)
        unless deleted_user_list.nil?
          deleted_user_list.each do |user|
            db_entry = ProfilUser.
              filter(:user => User.filter(:id_jointure_aaf => user[:id_jointure_aaf])).
              filter(:etablissement => Etablissement.filter(:code_uai => @cur_etb_uai)).
              select(:etablissement_id, :user_id, :profil_id).first
            remove_from_etb(db_entry.to_hash) unless db_entry.nil?
          end
        end
      end
    end

    def diff_telephone(numero)
      # - Table :telephone
      # create: nouveau tel ou nouvel utilisateur
      # update: maj du numéro pour un utilisateur 
      # QUE dans le cas où le type téléphone est pareil.
      # Aucune MAJ si une entrée avec le même numéro est présent, 
      # même si elle a un type différent car il peut avoir été modifié par l'utilisateur
      # delete: PAS DE DELETE (donnée utilisateur)
      #Si l'utilisateur, n'a pas d'id, c'est forcément un nouveau rattachement
      user_id = numero[:user][:id]
      if user_id.nil?
        add_data_to_create(:telephone, numero)
      else
        #Si après une alimentation, on change le type du téléphone, on
        #va se retrouver avec un autre téléphone recréé par l'alimentation...
        #Donc on s'assure que ce numéro n'existe pas déjà
        #On ne fait rien si c'est le cas
        db_entry = DB[:telephone].filter(:user_id => user_id, :numero => numero[:numero]).first
        if db_entry.nil?
          db_entry = DB[:telephone].filter(:user_id => user_id,
            :type_telephone_id => numero[:numero]).first
          if db_entry.nil?
            add_data_to_create(:telephone, numero)
          else
            #On update que dans le cas où l'on a l'utilisateur et le même type de téléphone
            add_data_to_update(:telephone, numero, db_entry)
          end
        end
      end
    end

    def diff_email(email)
      # - Table :email
      # create: nouvel email ou nouvel utilisateur
      # update: maj de l'email d'un utilisateur 
      # QUE dans le cas où il n'y a pas une entrée avec la même adresse.
      # delete: PAS DE DELETE (donnée utilisateur)
      
      #Si l'utilisateur, n'a pas d'id, c'est forcément un nouveau rattachement
      user_id = email[:user][:id]
      if user_id.nil?
        add_data_to_create(:email, email)
      else
        # L'utilisateur ne peut avoir qu'un seul email principal
        if DB[:email].filter(:user_id => user_id, :principal => true).count > 0
          email[:principal => false]
        end
        db_entry = DB[:email].filter(:user_id => user_id, :adresse => email[:adresse]).first
        if db_entry.nil?
          # On ne peut avoir qu'un seul mail academique
          db_entry = DB[:email].filter(:user_id => user_id, :academique => true)
          if db_entry.nil?
            add_data_to_create(:email, email)
          else
            add_data_to_update(:email, email, db_entry)
          end
        end
      end
    end

    def diff_relation_eleve(rel)
      # - Table :relation_eleve
      # create: nouvelle relation
      # update: changement du type de relation
      # delete: si eleve présent dans l'alimentation mais relation manquante par rapport à la BDD
      # Fait à la fin dans diff_delete_relation_eleve
      user_id = rel[:user][:id]
      eleve_id = rel[:eleve][:id]
      if user_id.nil? or eleve_id.nil?
        add_data_to_create(:relation_eleve, rel)
      else
        db_entry = DB[:relation_eleve].filter(:user_id => user_id, :eleve_id => eleve_id).first
        if db_entry.nil?
          add_data_to_create(:relation_eleve, rel)
        else
          add_data_to_update(:relation_eleve, rel, db_entry, [:user, :eleve])
        end
      end
    end

    #Renvois la liste des id d'élève présent dans BDD et dans l'alimentation
    def get_existing_eleve_id_list()
      #si l'elève n'a pas d'id c'est qu'il n'est pas présent en BDD
      eleve_id_list = @cur_etb_data[:relation_eleve].reject {|rel| rel[:eleve][:id].nil?}
      eleve_id_list.map! {|rel| rel[:eleve][:id]}.uniq!
      return eleve_id_list
    end

    def diff_delete_relation_eleve()
      #Check toutes les relation des eleves présents dans l'alimentation
      #et déjà créé en BDD
      eleve_id_list = get_existing_eleve_id_list()
      eleve_id_list.each do |eleve_id|
        DB[:relation_eleve].filter(:eleve_id => eleve_id).each do |rel_entry|
          rel_data = @cur_etb_data[:relation_eleve].
            find({[:user, :id] => rel_entry[:user_id], [:eleve, :id] => rel_entry[:eleve_id]})
          #Suppression de la relation eleve si elle est présente en BDD mais pas dans l'alimentation
          if rel_data.nil?
            add_data_to_delete(:relation_eleve, rel_entry)
          end
        end
      end
    end

    #Permet de savoir si un regroupement dans la base de donnée
    # a été renommé dans les XML.
    def regroupement_has_same_users(reg_entry, reg_data)
      #puts "regroupement_has_same_users(#{reg_entry}, #{reg_data})"
      #On récupère tous les membres du groupe alimentés par l'académie
      entry_members = DB[:membre_regroupement].
        join(:user, :id => :user_id).
        filter(:regroupement_id => reg_entry[:id]).
        exclude(:id_jointure_aaf => nil).
        select(:user_id, :id_jointure_aaf).all
      #puts "#{entry_members}"
      #On check si tous les membres du groupe en BDD sont dans le "nouveau" groupe XML
      entry_members.each do |entry_membre|
        data_member = @cur_etb_data[:membre_regroupement].
          find({regroupement: reg_data, [:user, :id] => entry_membre[:user_id]})
        if data_member.nil?
          if @is_complet
            return false
          #Dans le cas d'un delta l'utilisateur peut avoir été supprimé de l'établissement
          #au même moment
          else
            deleted_user = @cur_etb_data[:user].
              find({:deleted => true, :id_jointure_aaf => entry_membre[:id_jointure_aaf]})
            return false if deleted_user.nil?
          end
        end
      end

      #puts "HAS SAME USERS" if entry_members.length > 0
      return entry_members.length > 0
    end

    def find_renamed_regroupement(reg_data)
      #On boucle sur tous les regroupement de l'établissement qui ont déjà été alimentés
      req = Regroupement.
        filter(:etablissement => Etablissement.filter(:code_uai => @cur_etb_uai), :type_regroupement_id => reg_data[:type_regroupement_id]).
        exclude(:libelle_aaf => nil)
      req.each do |reg_entry|
        reg_entry = reg_entry.to_hash
        #On check si ce regroupement n'est pas présent dans l'alimentation
        data = @cur_etb_data[:regroupement].find({:libelle_aaf => reg_entry[:libelle_aaf],
          :type_regroupement_id => reg_entry[:type_regroupement_id]})

        if data.nil?
            #Si ils ont les même utilisateurs, on peut supposer qu'il s'agit simplement d'un renommage
            return reg_entry if regroupement_has_same_users(reg_entry, reg_data)
        end
      end

      return nil
    end

    def diff_regroupement(reg)
      # - Table :regroupement
      # create: seulement si on s'est assurer que la classe avec un nouveau libelle_aaf n'est pas un simple renommage
      # update: si niveau change (todo) mais aussi si libellé change, pour cela, il faut checker quand il y a un nouveau groupe
      # si un autre groupe ne se retrouve pas "vidé" dans la même operation, si c'est le cas alors on ne créer pas,
      # on ne fait que renommer
      # PAS DE DELETE : Trop de données importantes sont reliées à un groupe (cahier de texte, blog etc.)
      #On cherche donc parmis tous les regroupements de l'établissement qui ont un libelle_aaf
      #todo : Attention, on se base sur le fait que même sur un delta, TOUS les groupes de l'établissement
      #s'y retrouvent, vérifier si c'est bien le cas, sinon on ne pourra valider un renommage que lors des
      # complets
      existing_reg = Regroupement.
        filter(:etablissement => Etablissement.filter(:code_uai => @cur_etb_uai), :libelle_aaf => reg[:libelle_aaf]).
        first
      if existing_reg.nil?
        renamed_reg = find_renamed_regroupement(reg)
        #Il s'agit bien d'un nouveau regroupement
        if renamed_reg.nil?
          add_data_to_create(:regroupement, reg)
        else
          reg[:id] = renamed_reg[:id]
          #temp : hack pour que l'etablissement_id ne fasse pas parti de l'update
          # sinon on update le champs même s'il n'y a rien dedans...
          add_data_to_update(:regroupement, reg, renamed_reg, [:id, :etablissement])
        end
      else
        existing_reg = existing_reg.to_hash
        reg[:id] = existing_reg[:id]
        #temp : hack pour que l'etablissement_id ne fasse pas parti de l'update
        # sinon on update le champs même s'il n'y a rien dedans...
        add_data_to_update(:regroupement, reg, existing_reg, [:id, :etablissement])
      end
    end

    #Comme membre_regroupement et enseigne_regroupement ont la même structure, la fonction diff est la même
    def diff_rattach_regroupement(table_name, rattach_reg)
      # - Table :membre_regroupement et enseigne_regroupement
      # create : si nouveau rattachement
      # update : pas d'update
      # delete : si user plus dans établissement on supprime les rattachements. 
      # fait dans diff_delete_user
      # delete : peut aussi se faire lorsqu'un eleve est changé de classe
      # delete aussi quand un rattachement d'un groupe de travail n'est plus présent
      # voir diff_delete_membre_regroupement

      #Si l'utilisateur ou le regroupement n'ont pas d'id, c'est qu'ils sont nouveaux et que le rattachement est forcément
      # nouveau lui aussi
      user_id = rattach_reg[:user][:id]
      reg_id = rattach_reg[:regroupement][:id]
      create_rattach = false
      if user_id.nil? or reg_id.nil?
        create_rattach = true
      else
        rattach = DB[table_name].filter(:user_id => user_id, :regroupement_id => reg_id).first
        create_rattach = rattach.nil?
      end

      if create_rattach
        add_data_to_create(table_name, rattach_reg)
      end
    end

    #Supprime les rattachement de groupe (classe ou groupe de travail) présents
    #en BDD, mais non présent dans l'alimentation
    def diff_delete_membre_regroupement()
      eleve_id_list = get_existing_eleve_id_list()
      eleve_id_list.each do |eleve_id|
        membre_list = MembreRegroupement.
          filter(:user_id => eleve_id).
          filter(:regroupement => Regroupement.
            filter(:type_regroupement_id => ["CLS","GRP"], 
              :etablissement => Etablissement.filter(:code_uai => @cur_etb_uai))).
          select(:user_id, :regroupement_id).all

        membre_list.each do |membre|
          membre = membre.to_hash
          membre_data = @cur_etb_data[:membre_regroupement].
            find({
              [:user, :id] => membre[:user_id],
              [:regroupement, :id] => membre[:regroupement_id]
            })
          add_data_to_delete(:membre_regroupement, membre) if membre_data.nil?
        end
      end
    end

    def remove_unknown_parent_references(id_jointure_aaf)
      rel_to_delete = @cur_etb_data[:relation_eleve].find({[:user, :id_jointure_aaf] => id_jointure_aaf}, true)
      profil_to_delete = @cur_etb_data[:profil_user].find({[:user, :id_jointure_aaf] => id_jointure_aaf})

      unless rel_to_delete.nil?
        @cur_etb_data[:relation_eleve].delete_if{|rel| rel_to_delete.include?(rel)}
      end

      unless profil_to_delete.nil?
        @cur_etb_data[:profil_user].delete_if{|profil| profil_to_delete.include?(profil)}
      end 
    end

    #Cette fonction génère une structure intermédiaire représentant les changements à effectuer
    def generate_diff_etb
      #Je n'utilise pas le each du Hash cur_etb_data car j'ai besoin d'être sûr de l'ordre
      #d'appel (user doit être en premier)
      @cur_etb_data.each_key do |table|
        @cur_etb_data[table].each do |data|
          case table
            when :etablissement
              diff_etablissement(data)
            when :user
              #Cas d'un utilisateur supprimé dans l'alimentation.
              #Gérer à la fin dans le diff_delete_user
              if !data.keys.include?(:deleted)
                #Autre cas : quand un parent est créer juste parcequ'il a été trouvé
                #dans le fichier élève mais qu'il n'est pas présent dans le fichier parent
                #(on a qu'une donnée avec id_jointure_aaf)
                if data.keys == [:id_jointure_aaf]
                  #On va simplement retrouver l'id ent de la personne
                  #Au cas où il y a des modification de la relation_eleve
                  user = User[:id_jointure_aaf => data[:id_jointure_aaf]]
                  unless user.nil?
                    data[:id] = user.id
                  else
                    # Ce cas n'arrive normalement que pour les parents (alimentation précédente qui a foirée)
                    # et donc delta qui n'a pas toutes les infos, il faut supprimer les références à cet utilisateur
                    # dans les tables relation_eleve et profil_user pour éviter d'avoir des erreurs SQL...
                    remove_unknown_parent_references(data[:id_jointure_aaf])
                    #Todo gérer proprement l'erreur
                    puts "Parent #{data[:id_jointure_aaf]} spécifié dans un fichier élève mais inexistant dans la BDD et pas décrit dans le fichier parent."
                  end
                else
                  diff_user(data)
                end
              end
            when :profil_user
              diff_profil_user(data)
            when :telephone
              diff_telephone(data)
            when :email
              diff_email(data)
            when :relation_eleve
              diff_relation_eleve(data)
            when :regroupement
              diff_regroupement(data)
            when :membre_regroupement, :enseigne_regroupement
              diff_rattach_regroupement(table, data)
          end
        end
      end

      #La gestion de la suppression d'un utilisateur d'un établissement se fait tout à la fin
      #Et concerne plusieurs table (profil_user, membre_regroupement, enseigne_regroupement)
      diff_delete_user()
      diff_delete_relation_eleve()
      diff_delete_membre_regroupement()
      remove_deleted_elv_parents()
      remove_deleted_relation_parents()

      return @cur_etb_diff
    end
  end
end