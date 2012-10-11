#!ruby
#coding: utf-8

#Cette classe génère une vue (html pour l'instant)
module Alimentation
  class DiffView
    def generate_html(uai, diff, date, complet)
      @diff = diff
      @current_uai = uai
      @add_div = "<div class='alert alert-success'>"
      @upt_div = "<div class='alert'>"
      @del_div = "<div class='alert alert-error'>"
      @info_div = "<div class='alert alert-info'>"
      @end_div = "</div>"
      Dir.mkdir("diff") unless Dir.exists?("diff")
      alim_type = complet ? "complet" : "delta"
      f = File.open("diff/diff_#{uai}_#{date.to_s}_#{alim_type}.html", "w")
      f.puts("<html lang='fr'>
  <head>
    <meta content='text/html; charset=UTF-8' http-equiv='Content-Type' />
    <link href='css/bootstrap.css' media='screen' rel='stylesheet' type='text/css' />
    <script src='js/jquery.min.js'></script>
    <script src='js/bootstrap.js'></script>
    <title>Alimentation : Différences</title>
    <style>
      .alert {
        display: inline-block;
      }
      body {
        margin: 10px;
      }
    </style>
    <script>
    $(function(){
      $('div[rel=popover]').each(function(i){
          /*splited = $(this).attr('data-content-dede').split('|');
          popContent = '';
          if (splited.length > 0){
            for(var i = 0 ; i < splited.length - 1 ; i++){
              popContent = splited[i] + '</br>';
            }
          }
          $(this).popover({content: popContent});*/
          $(this).popover();
        });
    });
    </script>
  </head>
  <body>")
      f.puts("<h1>Changements dans les regroupements</h1>")
      f.puts("<h2>Classes</h2>")
      add_group_changes(f, "CLS")
      f.puts("<h2>Groupes</h2>")
      add_group_changes(f, "GRP")
      f.puts("<h1>Changements utilisateurs</h1>")
      f.puts("<h2>Personnel d'établissement</h2>")
      add_user_changes(f)
      f.puts("<h2>Elèves</h2>")
      add_user_changes(f, "ELV")
      f.puts("<h2>Parents</h2>")
      add_user_changes(f, "PAR")
      f.puts("</body></html>")

      f.close()
    end

    def get_operation_css_class(operation)
      case operation
        when :create
          return 'alert alert-success'
        when :update
          return 'alert'
        when :delete
          return 'alert alert-error'
      end
    end

    #Créer un div représentant une opération sur une donnée
    #Ajout, Update, Suppression
    def add_operation(f, operation, value, div=nil)
      case operation
        when :create
          div = @add_div if div.nil?
          icon = "icon-plus-sign"
        when :update
          div = @upt_div if div.nil?
          icon = "icon-refresh"
        when :delete
          div = @del_div if div.nil?
          icon = "icon-minus-sign"
      end
      f.puts(div)
      f.puts("<i class='#{icon}'></i> #{value}")
      f.puts(@end_div)
    end

    def get_prof_nb_attach(user_id, reg_id)
      DB[:enseigne_regroupement].
        filter(:user_id => user_id, :regroupement_id => reg_id).
        count()
    end

    def add_prof_matiere(liste_prof, mode, ens)
      prof_index = liste_prof[mode].index{|p| p[:user] == ens[:user]}
      if prof_index.nil?
        prof = liste_prof[mode].push({user: ens[:user]}).last
      else
        prof = liste_prof[mode][prof_index]
      end

      prof[:principal] = ens[:prof_principal]
      prof[:matieres] = [] if prof[:matieres].nil?
      prof[:matieres].push(ens[:matiere_enseignee_id])
    end

    #Renvois la liste des profs ainsi que les matières enseignées
    #Sous forme de Hash :create, :update, :delete
    def get_liste_prof(reg)
      liste_prof = {create: [], update: [], delete: []}
      @diff[:enseigne_regroupement][:create].each do |ens|
        if ens[:regroupement] == reg
          #pour savoir s'il s'agit d'un nouveau prof ou simplement
          #d'un prof qui a une matière en plus
          #il faut regarder dans la BDD actuelle et si l'utilisateur est déjà relié
          #au groupe il s'agit d'un update
          mode = :create
          if !ens[:regroupement][:id].nil? and ens[:user][:id]
            count = get_prof_nb_attach(ens[:user][:id], ens[:regroupement][:id])
            mode = :update if count > 0
          end

          add_prof_matiere(liste_prof, mode, ens)
        end
      end

      #todo : gérer aussi les updates qui peuvent avoir lieu si le status
      #prof_principal change
      @diff[:enseigne_regroupement][:delete].each do |ens|
        if ens[:regroupement] == reg
          mode = :delete
          #une suppression de rattachement au groupe ne signifie pas forcément
          #que la personne n'enseigne plus dans ce groupe, il faut donc s'assurer de ça
          if !ens[:regroupement][:id].nil? and ens[:user][:id]
            del_list = @diff[:enseigne_regroupement][:delete].reject do |ens|
              ens[:regroupement] != reg
            end
            nb_attach = get_prof_nb_attach(ens[:user][:id], ens[:regroupement][:id])
            mode = :update if nb_attach > del_list.length
          end

          add_prof_matiere(liste_prof, mode, ens)
        end
      end

      return liste_prof
    end

    def write_group_content(f, reg)
      f.write("Professeurs : ")
      liste_prof = get_liste_prof(reg)
      liste_prof.each do |k, v|
        #matiere = MatiereEnseignee[ens[:matiere_enseignee_id]].libelle_edition
        #matiere += ", <strong>principal</strong>" if ens[:prof_principal]
        liste_prof[k].each do |prof|
          matiere_list = ""
          prof[:matieres].each do |mat_id|
            alert_plus = '<div class="alert alert-success"><i class="icon-plus-sign"></i>'
            matiere_list += "#{alert_plus}#{MatiereEnseignee[mat_id].libelle_edition}</div></br>"
          end

          div = "<div class='#{get_operation_css_class(k)}' rel='popover' data-content='#{matiere_list}' data-original-title='Matières enseignées'>"

          principal = " <span class='label label-info'>principal</span>" if prof[:principal]
          add_operation(f, k,
          "#{prof[:user][:prenom]} #{prof[:user][:nom]}#{principal}", div)
        end
      end
      f.puts("</br>")
      f.write("Elèves : ")
      @diff[:membre_regroupement][:create].each do |elv|
        if elv[:regroupement] == reg
          add_operation(f, :create, "#{elv[:user][:prenom]} #{elv[:user][:nom]}")
        end
      end

      @diff[:membre_regroupement][:delete].each do |elv|
        if elv[:regroupement] == reg
          add_operation(f, :delete, "#{elv[:user][:prenom]} #{elv[:user][:nom]}")
        end
      end
    end

    #Check toutes les différences de rattachement pour voir s'il y en a dans le regroupement
    #Passé en paramètre
    def is_reg_rattach_modified(etb_reg)
      index = @diff[:membre_regroupement][:update].index {|reg| reg[:updated][:id] == etb_reg[:id]}
      index = @diff[:membre_regroupement][:delete].index {|reg| reg[:id] == etb_reg[:id]} if index.nil?
      index = @diff[:enseigne_regroupement][:update].index {|reg| reg[:updated][:id] == etb_reg[:id]} if index.nil?
      index = @diff[:enseigne_regroupement][:delete].index {|reg| reg[:id] == etb_reg[:id]} if index.nil?

      return !index.nil?
    end

    def add_group_changes(f, grp_type_id)
      phrase = grp_type_id == "CLS" ? "de la classe" : "du groupe"
      #On affiche toutes les créations de groupes
      @diff[:regroupement][:create].each do |reg|
        if reg[:type_regroupement_id] == grp_type_id
          f.puts(@info_div)
          #add_operation(f, @add_div, reg[:libelle_aaf])
          f.puts("<h4><i class='icon-plus-sign'></i> #{reg[:libelle_aaf]}</h4>")
          write_group_content(f, reg)
          f.puts("#{@end_div}</br>")
        end
      end

      #puis aussi toutes les modifications de groupes existant
      #On boucle donc sur tous les groupes de l'établissement pour voir si on a des modifs dessus
      #dans les tables enseigne_regroupement ou membre_regroupement
      etb_reg_list = DB[:regroupement].
        filter(:etablissement_id => @current_uai, :type_regroupement_id => grp_type_id).
        select(:id).all

      etb_reg_list.each do |etb_reg|
        index_reg = @diff[:regroupement][:update].index {|reg| reg[:updated][:id] == etb_reg[:id]}
        unless index_reg.nil?
          reg_update = @diff[:regroupement][:update][index_reg]
          prev_name = reg_update[:current][:libelle_aaf]
          new_name = reg_update[:updated][:libelle_aaf]
          title = "<h4><i class='icon-refresh'></i> #{prev_name} => #{new_name} (#{etb_reg[:lib]})</h4>"
        else
          title = "<h4>#{etb_reg[:libelle_aaf]} (#{etb_reg[:lib]})</h4>"
        end

        write_group = index_reg.nil?
        #Si le regroupement n'a pas changé.
        #Check s'il n'y a pas de modifications dans les rattachement au reg
        unless write_group
          write_group = is_reg_rattach_modified(etb_reg)
        end

        if write_group
          f.puts(@info_div)
          f.puts(title)
          write_group_content(f, etb_reg)
          f.puts("#{@end_div}</br>")
        end
      end
    end

    #temp : Se fait sur le libellé si c'est un élève ou un parent
    #et si nil, on cherche s'il y a un code_men
    def user_has_profil(user, profil_id)
      #cherche dans les créations
      if user[:id].nil?
        profil_user_list = @diff[:profil_user][:create].reject{|p| p[:user] != user}
      #Ou dans la BDD
      else
        profil_user_list = DB[:profil_user].
          filter(:user_id => user[:id], :etablissement_id => @current_uai).all
      end

      profil_user_list.each do |profil|
        if profil_id.nil?
          #On récupère tous les profil ayant un code_men
          profil_men = DB[:profil].exclude(:code_men => nil).all
          ind = profil_men.index {|prf| prf[:id] == profil[:profil_id]}
          return true unless ind.nil?
        else
          return true if profil_id == profil[:profil_id]
        end
      end

      return false
    end

    #On cherche à récupérer la liste de tous les utilisateurs
    #Qui on été modifié, cela comprend des modifications
    #sur la table user, profil_user, telephone et relation_eleve
    def get_user_diff_list()
      to_check = [[:relation_eleve, :profil_user, :telephone, :user], [:create, :update, :delete]]
      user_list = []
      to_check[0].each do |table|
        to_check[1].each do |operation|
          @diff[table][operation].each do |obj|
            if operation == :update
              obj = obj[:updated]
            end

            user = table == :user ? obj : obj[:user]
            #Pour les cas de delete, on se refère directement au user_id
            if user.nil? and !obj[:user_id].nil?
              user = DB[:user].filter(:id => obj[:user_id]).first
            end
            raise "User à nil dans le diff view" if user.nil?
            #Attention, j'utilise :usr car :user est le nom de la table
            user_ind = user_list.index {|u| u[:usr] == user}
            if user_ind.nil?
              user_diff = {usr: user}
              user_list.push(user_diff)
            else
              user_diff = user_list[user_ind]
            end
            user_diff[table] = {} if user_diff[table].nil?
            user_diff[table][operation] = obj
          end
        end
      end

      return user_list
    end

    def add_user_changes(f, profil_lib=nil)
      #todo : voir pourquoi on a parfois besoin de id_jointure_aaf au lieu de directement comparer les user
      user_list = get_user_diff_list()
      user_list.each do |user_diff|
        #puts user_diff
        if user_has_profil(user_diff[:usr], profil_lib)
          #Tout d'abord on check s'il s'agit d'un ajout, d'une modification ou d'une suppression
          # pour l'établissement
          #Si l'utilisateur vient d'être créé c'est forcément un ajout
          new_user = false
          deleted_user = false
          if !user_diff[:profil_user].nil?
            if !user_diff[:user].nil?
              new_user = !user_diff[:user][:create].nil? or !user_diff[:profil_user][:create].nil?
            end
            deleted_user = !user_diff[:profil_user][:delete].nil?
          end

          name = "#{user_diff[:usr][:prenom]} #{user_diff[:usr][:nom]}"
          if new_user
            add_operation(f, :create, name)
          elsif deleted_user
            add_operation(f, :delete, name)
          else
            add_operation(f, :update, name)
          end
        end
      end

      # @diff[:user][:create].each do |user|
      #   f.puts(@add_div)
      #   f.puts("Création de #{user[:prenom]} #{user[:nom]}</br>")
      #   @diff[:profil_user][:create].each do |profil|
      #     if profil[:user][:id_jointure_aaf] == user[:id_jointure_aaf]
      #       prof_lib = Profil[profil[:profil_id]].libelle
      #       f.puts("Rattaché en tant que #{prof_lib}</br>")
      #     end
      #   end

      #   @diff[:telephone][:create].each do |tel|
      #     if tel[:user] == user
      #       lib = tel[:type_telephone_id] == "MAIS" ? "Téléphone Fixe : " : "Téléphone secondaire : "
      #       f.puts("#{lib}#{tel[:numero]}</br>")
      #     end
      #   end

      #   @diff[:relation_eleve][:create].each do |rel|
      #     if rel[:eleve][:id_jointure_aaf] == user[:id_jointure_aaf]
      #       rel_lib = TypeRelationEleve[rel[:type_relation_eleve_id]].lib
      #       f.puts("Sous la responsabilité de #{rel[:user][:prenom]} #{rel[:user][:nom]} (#{rel_lib})</br>")
      #     elsif rel[:user][:id_jointure_aaf] == user[:id_jointure_aaf]
      #       rel_lib = TypeRelationEleve[rel[:type_relation_eleve_id]].lib
      #       f.puts("Responsable de #{rel[:eleve][:prenom]} #{rel[:eleve][:nom]} (#{rel_lib})</br>")
      #     end
      #   end
      #   f.puts(@end_div)
      # end
    end
  end
end