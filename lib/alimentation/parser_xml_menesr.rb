#!ruby
#coding: utf-8

#Hash de correspondance des champs XML avec la structure de BDD
#Les champs absents ne sont pas utilisés dans la BDD
# PERSON = {
#   ENTPersonJointure: User[:id_jointure_aaf],
#   ENTPersonDateNaissance: User[:date_naissance], #Nécessite conversion date
#   sn: User[:nom],
#   givenName: User[:prenom],
#   personalTitle: User[:sexe], #Nécessite conversion M. Mme. Mlle => M, F
#   ENTPersonStructRattach: ProfilUser.etablissement_id, #Nécessite conversion id=>UAI
#   homePhone: Telephone.numero,
#   telephoneNumber: Telephone.numero,
#   ENTPersonAdresse: User.adresse,
#   ENTPersonCodePostal: User.code_postal,
#   ENTPersonVille: User.ville,
#   ENTPersonPays: User.ville, #Si diffère de FRANCE
#   mail: Email #N'existe que pour les prof et le mail académique
# }

# ELEVE = {
#   ENTEleveAutoriteParentale: RelationEleve, #Faire lien avec id de jointure
#   ENTElevePere: TypeRelationEleve, #Obsolète apparement 
#   ENTEleveMere: TypeRelationEleve, #Obsolète apparement 
#   ENTElevePersRelEleve1: RelationEleve,
#   ENTEleveQualitePersRelEleve1: TypeRelationEleve,
#   ENTElevePersRelEleve2: RelationEleve,
#   ENTEleveQualitePersRelEleve2: TypeRelationEleve,
#   ENTEleveClasses: MembreRegroupement, #Faire le liens entre libelle_aaf et id interne
#   ENTEleveGroupes: MembreRegroupement #Idem
# }

# PEN = {
#   #Liste des matières enseignées par regroupement
#   #Ne permet pas de savoir quelle matière est enseignée dans un regroupement
#   #Donc on va sûrement mettre toutes les matières dans tous les groupes
#   #Puis on laissera aux utilisateurs le choix d'être un peu plus fin.
#   ENTAuxEnsMatiereEnseignEtab: EnseigneRegroupement.matiere_enseignee_id,
#   ENTAuxEnsClasses: EnseigneRegroupement.regroupement_id,
#   ENTAuxEnsGroupes: EnseigneRegroupement.regroupement_id,
#   ENTAuxEnsClassesPrincipal: EnseigneRegroupement.prof_principal
#   PersEducNatPresenceDevantEleves: permet de savoir si oui ou non une personne est prof
#   ENTPersonFonctions: Indication sur le profil de la personne
# }

# STRUCT = {
#   ENTStructureJointure: Etablissement.id, #Faire le lien avec UAI
#   ENTStructureUAI: Etablissement.id,
#   ENTStructureNomCourant: Etablissement.nom, #Nom de l'établissement (séparateur "-" apparement)
#   ENTStructureTypeStruct: TypeEtablissement, #Faire le lien à la main
#   ENTEtablissementContrat: TypeEtablissement.type_contrat,
#   postOfficeBox: Etablissement.adresse, #Si renseigné mettre BP
#   street: Etablissement.adresse,
#   postalCode: Etablissement.code_postal,
#   l: Etablissement.ville,
#   telephoneNumber: Etablissement.telephone,
#   facsimileTelephoneNumber: Etablissement.fax
# }
module Alimentation
  # Classe d'erreur quand il manque des données pour un profil
  class MissingDataError < StandardError
  end

  # Classe utilisée quand il y a des erreurs sur les données
  class WrongDataError < StandardError
  end

  class ParserXmlMenesr
    CATEGORIE_ELEVE = "Eleve"
    CATEGORIE_PARENT = "PersRelEleve"
    CATEGORIE_PEN = "PersEducNat"
    #Todo utiliser code_men ou autre pour les profils
    PROFIL_ELEVE = "ELV"
    PROFIL_PARENT = "PAR"
    PROFIL_ENS = "ENS"

    def get_attr(node, name, type=:string)
      attr_value = nil
      val = node.at_css("attr [name='#{name}'] value, modification [name='#{name}'] value")
      if !val.nil? and val.content != ""
        case type
          when :string
            attr_value = val.content
          when :int
            attr_value = val.content.to_i
        end
      end

      return attr_value
    end

    def get_multiple_attr(node, name, type=:string)
      val = node.css("attr [name='#{name}'] value, modification [name='#{name}'] value")
      if !val.nil?
        val = val.to_a().map {|v| v.content}
        val.keep_if {|v| v != ""}
        val.map! {|v| v.to_i} if type == :int
      end
      return val
    end



    #Certains attributs multiples sont sous la forme id_etb$attr
    #Renvois donc une liste avec seulement les attributs de l'etablissement
    def get_multiple_attr_etb(node, name)
      attr_list = get_multiple_attr(node, name)
      attr_list.map! do |attr|
        splitted = attr.split('$')
        if splitted.length > 1 and splitted[0] == @cur_etb_xml_id
          attr = splitted[1]
        end
      end
      return attr_list
    end

    #L'établissement est référencé par un ID interne dans l'xml
    #Cette fonction le récupère, c'est nécessaire pour s'assurer des rattachement
    #dans le fichier XML
    def find_etb_xml_id(file_list)
      xml_id = nil
      etb_file = file_list.select { |name| File.basename(name) =~ /EtabEducNat/}
      if etb_file.length == 1
        f = File.open(etb_file[0])
        doc = Nokogiri::XML(f)
        doc.css("addRequest").each do |node|
          code_uai = get_attr(node, "ENTEtablissementUAI")
          unless code_uai.nil?
            #On s'assure que dans le fichier EtabEducNat il existe bien
            #un etablissement avec l'uia présente dans le nom du fichier
            if code_uai == @cur_etb_uai
              xml_id = get_attr(node, "ENTStructureJointure")
            end
          end
        end

        f.close()
      end

      return xml_id
    end

    def parse_user(node, categorie)
      #On s'assure qu'il s'agit bien de la categorie souhaitée
      cat = get_attr(node, "categoriePersonne")
      if cat.nil? or cat != categorie
        raise WrongDataError.new("Catégorie #{categorie} attendue et #{cat} trouvée.")
      end

      #Et que les données obligatoire (idJointure, nom, prenom) sont présentent
      identifier = node.at_css("identifier id")
      identifier = identifier.content.to_i if identifier
      id_jointure = get_attr(node, "ENTPersonJointure", :int)
      nom = get_attr(node, 'sn')
      prenom = get_attr(node, 'givenName')
      
      if nom.nil? or prenom.nil? or id_jointure.nil?
        raise MissingDataError.new(
          "Au moins une des données suivante est manquante nom=#{nom} prenom=#{prenom} id_jointure=#{id_jointure}"
          )
      end

      if identifier != id_jointure
        raise WrongDataError.new("Champs identifier (#{identifier}) et ENTPersonJointure (#{id_jointure}) différents pour #{prenom} #{nom}.") 
      end

      #L'utilisateur peut déjà avoir été créer temporairement (cas d'un enfant dont les parents sont déclarés)
      parsed_user = @cur_etb_data[:user].find_or_add({:id_jointure_aaf => id_jointure})
      #   ENTPersonDateNaissance: User[:date_naissance], #Nécessite conversion date
      date_naissance = get_attr(node, "ENTPersonDateNaissance")
      #puts "#{date_naissance}"
      begin
        parsed_user[:date_naissance] = Date.parse(date_naissance)
      rescue
        Ramaze::Log.info("Date de naissance manquante ou invalide pour l'utilisateur #{parsed_user.inspect}")
        if categorie == CATEGORIE_ELEVE
          raise MissingDataError.new("Date de naissance manquante pour #{prenom} #{nom} ##{id_jointure}")
        end
      end
      #   sn: User[:nom],
      parsed_user[:nom] = nom
      #   givenName: User[:prenom],
      parsed_user[:prenom] = prenom
      #   personalTitle: User[:sexe], #Nécessite conversion M. Mme. Mlle => M, F
      titre = get_attr(node, 'personalTitle')
      parsed_user[:sexe] = titre == "M." ? "M" : "F"
      #   ENTPersonAdresse: User.adresse,
      parsed_user[:adresse] = get_attr(node, "ENTPersonAdresse")
      #   ENTPersonCodePostal: User.code_postal,
      parsed_user[:code_postal] = get_attr(node, "ENTPersonCodePostal")
      #   ENTPersonVille: User.ville,
      parsed_user[:ville] = get_attr(node, "ENTPersonVille")
      #   ENTPersonPays: User.ville, #Si diffère de FRANCE
      pays = get_attr(node, "ENTPersonPays")
      parsed_user[:ville] += " #{pays}" if !parsed_user[:ville].nil? and !pays.nil? and pays != "FRANCE"
      parsed_user[:date_last_maj_aaf] = DateTime.now

      return parsed_user
    end

    def find_pen_profil_id(node, user)
      # ENTPersonStructRattach: ProfilUser.etablissement_id, #Nécessite conversion id=>UAI
      # La structure de rattachement n'est pas forcément l'établissement
      # actuellement parsé
      struct_rattach = get_attr(node, 'ENTPersonStructRattach')
      
      #La personne peut avoir plusieurs fonctions, on cherche celle sur son établissement
      # TODO : chercher dans les multiples fonctions
      fonction = get_multiple_attr(node, "ENTPersonFonctions")[0]
      splitted_fct = fonction.split('$') unless fonction.nil?
      #Parfois struct_rattach n'est pas renseignée donc on peut tenter de le trouver
      #dans ENTPersonFonctions
      if struct_rattach.nil? and !splitted_fct.nil?
        struct_rattach = splitted_fct[0]
      end
      if struct_rattach.nil?
        raise MissingDataError.new("Structure de rattachement manquante pour le personnel #{user}")
      end

      if !splitted_fct.nil? and splitted_fct.length > 1
        code_men = splitted_fct[1]
        #Pour l'instant le profil est en fonction du code_men de la fonction
        #pour tous les pen
        #todo : utiliser la discipline pour préciser le profil (Principal et Principal Adjoint)
        profil = Profil[:code_men => code_men]
      end

      #Si profil pas trouvé, alors on suppose que c'est un prof
      #todo : Peut-être mettre administratif au lieu de prof ?
      profil = Profil[:id => PROFIL_ENS] if profil.nil?

      return profil.id
    end

    # Ne traite que les Eleve et PersEtabEducNat
    # Le profil parent est créé avec les élèves car certaines personnes
    # ne sont que correspondant
    def add_profil_to_user(user, profil_id)
      profil_user = {etablissement: @cur_etb, user: user, profil_id: profil_id}
      @cur_etb_data[:profil_user].find_or_add( 
        {:etablissement => @cur_etb, :user => user}, profil_user)
    end

    def add_phone_to_user(user, tel, default_type)
      #On cherche à savoir si c'est un portable
      if tel[0,2] == "06" or tel[0,5] == "+33 6"
        type_id = "PORT"
      else
        type_id = default_type
      end
      tel_hash = {numero: tel, user: user, type_telephone_id: type_id}
      @cur_etb_data[:telephone].find_or_add({:numero => tel, :user => user}, tel_hash)
    end

    #Parse les rattachement à un regroupement pour les prof et les élèves
    def parse_regroupement(node, attr_name, reg_type_id, user, matiere_list=nil)
      reg_list = get_multiple_attr_etb(node, attr_name)
      reg_list.each do |code_aaf|
        #Les fichiers xml ne nous fournissent pas la liste des différents classes et groupes de l'établissement
        #on doit donc la créer nous même à partir des rattachements d'élève
        type_reg = TypeRegroupement[:id => reg_type_id]
        unless type_reg.nil?
          reg = @cur_etb_data[:regroupement].find_or_add( 
            {etablissement: @cur_etb, libelle_aaf: code_aaf, type_regroupement_id: type_reg.id})
          #Le libellé par défaut est le code aaf
          reg[:libelle] = code_aaf if reg[:libelle].nil?

          #Les classes ont un niveau
          if reg_type_id == "CLS"
            niv_lib = get_attr(node, "ENTEleveLibelleMEF")
            niveau = DB[:niveau].filter(:libelle => niv_lib).first
            niveau = DB[:niveau].first if niveau.nil?
            reg[:niveau_id] = niveau[:id]
          end

          #Si pas de matière enseignée il s'agit d'un élève
          if matiere_list.nil?
            @cur_etb_data[:membre_regroupement].find_or_add({:regroupement => reg, :user => user})
          #Sinon d'un prof
          else
            #   ENTAuxEnsClassesPrincipal: EnseigneRegroupement.prof_principal
            classes_principal = get_multiple_attr_etb(node, "ENTAuxEnsClassesPrincipal")
            prof_principal = false
            classes_principal.each { |cls_code| prof_principal = true if cls_code == code_aaf }

            matiere_list.each do |mat_id|
              @cur_etb_data[:enseigne_regroupement].find_or_add(
                {:regroupement => reg, :user => user, :matiere_enseignee_id => mat_id, 
                  :prof_principal => prof_principal})
            end
          end
        end
      end
    end

    def parse_eleve(node, eleve)
      #Parsing specific à l'élève
      #   ENTEleveStructRattachId
      eleve[:id_sconet] = get_attr(node, "ENTEleveStructRattachId", :int)
      if eleve[:id_sconet].nil?
        #raise MissingDataError.new("ENTEleveStructRattachId (id sconet) manquant pour l'élève #{eleve}")
      end

      # ENTPersonStructRattach: ProfilUser.etablissement_id, #Nécessite conversion id=>UAI
      # La structure de rattachement n'est pas forcément l'établissement
      # actuellement parsé
      struct_rattach = get_attr(node, 'ENTPersonStructRattach')
      if struct_rattach.nil?
        raise MissingDataError.new("Structure de rattachement manquante pour l'élève #{user}")
      end

      add_profil_to_user(eleve, PROFIL_ELEVE)
      #
      # Gestion des relations élève (parents, correspondants etc)
      #

      #   ENTEleveAutoriteParentale: RelationEleve, #Faire lien avec id de jointure
      rel_eleve_list = get_multiple_attr(node, "ENTEleveAutoriteParentale", :int)
      #   ENTElevePere: TypeRelationEleve, #Obsolète apparement
      pere_id = get_attr(node, "ENTElevePere", :int)
      #   ENTEleveMere: TypeRelationEleve, #Obsolète apparement
      mere_id = get_attr(node, "ENTEleveMere", :int)
      #   ENTElevePersRelEleve1: RelationEleve,
      rel_1_id = get_attr(node, "ENTElevePersRelEleve1", :int)
      rel_eleve_list.push(rel_1_id) unless rel_1_id.nil?
      #   ENTEleveQualitePersRelEleve1: TypeRelationEleve,
      rel_1_type = get_attr(node, "ENTEleveQualitePersRelEleve1")
      #   ENTElevePersRelEleve2: RelationEleve,
      rel_2_id = get_attr(node, "ENTElevePersRelEleve2", :int)
      rel_eleve_list.push(rel_2_id) unless rel_2_id.nil?
      #   ENTEleveQualitePersRelEleve2: TypeRelationEleve,
      rel_2_type = get_attr(node, "ENTEleveQualitePersRelEleve2")

      rel_eleve_list.each do |id|
        parent = @cur_etb_data[:user].find_or_add({:id_jointure_aaf => id})

        #Seule les personnes ayant une autorité parentale sur l'enfant ont un profil
        #parent dans l'ENT. Les autres sont rentrés à titre informatif dans laclasse.com
        parent_list = get_multiple_attr(node, "ENTEleveAutoriteParentale", :int)
        if parent_list.include?(id)
          #Création du profil parent
          add_profil_to_user(parent, PROFIL_PARENT)
        end

        case parent[:id_jointure_aaf]
          when pere_id
            rel_id = "PERE"
          when mere_id
            rel_id = "MERE"
          when rel_1_id
            if rel_1_type == "Responsable financier"
              rel_id = "FINA"
            else
              rel_id = "CORR"
            end
          when rel_2_id
            if rel_2_type == "Responsable financier"
              rel_id = "FINA"
            else
              rel_id = "CORR"
            end
        end

        #puts "parent #{parent[:id_jointure_aaf].inspect} #{rel_1_id.inspect} #{rel_2_id.inspect} #{pere_id.inspect} #{mere_id.inspect}"
        if !rel_id.nil?
          type_relation = TypeRelationEleve[:id => rel_id]
          relation = {user: parent, eleve: eleve, type_relation_eleve_id: type_relation.id}
          @cur_etb_data[:relation_eleve].find_or_add({user: parent, eleve: eleve}, relation)
        end
      end

      #   ENTEleveClasses: MembreRegroupement, #Faire le liens entre libelle_aaf et id interne
      # todo : gérer les codes mef de la classe et le niveau
      parse_regroupement(node, "ENTEleveClasses", "CLS", eleve)
      #   ENTEleveGroupes: MembreRegroupement #Idem
      parse_regroupement(node, "ENTEleveGroupes", "GRP", eleve)
    end

    def parse_all_eleves(xml_doc)
      xml_doc.css("addRequest, modifyRequest").each do |node|
        eleve = parse_user(node, CATEGORIE_ELEVE)
        parse_eleve(node, eleve) unless eleve.nil?
      end
    end

    def parse_enseignant(node, enseignant)
      #   mail: Email 
      # N'existe que pour les prof et le mail académique
      adresse = get_attr(node, "mail")
      unless adresse.nil?
        email_hash = {adresse: adresse, user: enseignant}
        email_hash[:academique] = true if adresse.index(/@ac-.*\.fr/)
        @cur_etb_data[:email].find_or_add(email_hash)
      end

      profil_id = find_pen_profil_id(node, enseignant)
      add_profil_to_user(enseignant, profil_id)

      #   ENTAuxEnsMatiereEnseignEtab: EnseigneRegroupement.matiere_enseignee_id
      matiere_list = get_multiple_attr_etb(node, "ENTAuxEnsMatiereEnseignEtab")
      unless matiere_list.nil?
        #Les matières sont identifiées dans le XML par leur libellé
        matiere_list.map! do |mat|
          m = MatiereEnseignee[:libelle_long => mat]
          if m.nil? and !mat.nil? and mat.length > 0
            #Les id de matière non BCN sont du type 9999XXX donc sont plus grand
            #que n'importe quel id de la BCN, on prend donc le dernier id de la liste
            # et on l'incremente
            last_id = DB[:matiere_enseignee].select(:id).order(:id).last
            #C'est peut-etre la première matière hors BCN
            last_id[:id] = 9999000 if last_id[:id] < 9999000
            new_id = last_id[:id] + 1
            #Dangereux
            MatiereEnseignee.unrestrict_primary_key
            m = MatiereEnseignee.create(:id => new_id, :libelle_long => mat,
              :libelle_edition => mat, :famille_matiere_id => 0)
            puts "Matière #{mat} inconnue nouvel id #{m.id}"
          end
          id = m.id unless m.nil?
        end
        #   ENTAuxEnsClasses: EnseigneRegroupement.regroupement_id
        parse_regroupement(node, "ENTAuxEnsClasses", "CLS", enseignant, matiere_list)
        #   ENTAuxEnsGroupes: EnseigneRegroupement.regroupement_id
        parse_regroupement(node, "ENTAuxEnsGroupes", "GRP", enseignant, matiere_list)
      end
    end

    def parse_all_pens(xml_doc)
      xml_doc.css("addRequest, modifyRequest").each do |node|
        pen = parse_user(node, CATEGORIE_PEN)

        #   PersEducNatPresenceDevantEleves: permet de savoir si oui ou non une personne est prof
        enseigne = get_attr(node, "PersEducNatPresenceDevantEleves")
        if !pen.nil? and enseigne == 'O'
          parse_enseignant(node, pen)
        end
      end
    end

    def parse_all_parents(xml_doc)
      xml_doc.css("addRequest, modifyRequest").each do |node|
        #On met nil comme profil car le profil parent est définit lors du parsing de l'élève
        parent = parse_user(node, CATEGORIE_PARENT)

        #   homePhone: Telephone.numero
        #a noter qu'il ne s'agit pas forcément du téléphone de la maison
        #donc on check si c'est un portable au cas où...
        #Ah spielberg...
        telephone_maison = get_attr(node, "homePhone")
        add_phone_to_user(parent, telephone_maison, "MAIS") unless telephone_maison.nil?
        #   telephoneNumber: Telephone.numero,
        tel = get_attr(node, "telephoneNumber")
        add_phone_to_user(parent, tel, "AUTR") unless tel.nil?
        # Spécifique au SDET V4 donc pas encore là
        mobile = get_attr(node, "mobile")
        add_phone_to_user(parent, mobile, "PORT") unless mobile.nil?
      end
    end

    def parse_etab_educ_nat(xml_doc)
      #TODO créer les établissements quand ils n'existent pas
      xml_doc.css("addRequest, modifyRequest").each do |node|
        uai = get_attr(node, 'ENTEtablissementUAI')
        etb = @cur_etb_data[:etablissement].find_or_add({:code_uai => uai})
        etb[:siren] = get_attr(node, 'ENTStructureSIREN')
        #Le nom est apparement toujours sous cette forme
        # TYPE DE STRUCTURE-NOM DE L'ETAB-ac-lyon
        nom_complexe = get_attr(node, 'ENTStructureNomCourant')
        nom_decoupe = nom_complexe.split('-')
        #Attention ce n'est pas spécifié dans le SDET alors on se méfit
        if nom_decoupe.length > 1
          etb[:nom] = nom_decoupe[1]
        else
          etb[:nom] = nom_complexe
        end

        etb[:adresse] = get_attr(node, 'street')
        etb[:code_postal] = get_attr(node, 'postalCode')
        #todo : gérer la commune avec une table externe et trouver une solution pour les boites postales
        etb[:ville] = get_attr(node, 'l')
        boite_postale = get_attr(node, 'postOfficeBox')
        etb[:ville] += " BP #{boite_postale}" unless boite_postale.nil?
        etb[:telephone] = get_attr(node, 'telephoneNumber')
        etb[:fax] = get_attr(node, 'facsimileTelephoneNumber')

        #Création du type d'établissement à la volé s'il le faut
        type_nom = get_attr(node, 'ENTStructureTypeStruct')
        type_contrat = get_attr(node, 'ENTEtablissementContrat')
        type_etab = {:nom => type_nom, :type_contrat => type_contrat}
        type_etab_model = TypeEtablissement.find_or_create(type_etab)

        etb[:type_etablissement_id] = type_etab_model.id
      end
    end

    def find_deleted_users(xml_doc)
      xml_doc.css("deleteRequest").each do |node|
        deleted_user_id = node.at_css("identifier id")
        unless deleted_user_id.nil?
          deleted_user_id = deleted_user_id.content.to_i
          #Petit hack : on rajout un user avec le flag deleted
          #diff_generator sait alors qu'il faut le supprimer de l'établissement
          @cur_etb_data[:user].find_or_add({:id_jointure_aaf=>deleted_user_id, :deleted=>true})
        end
      end
    end

    def parse_file(name)
      f = File.open(name)
      doc = Nokogiri::XML(f)

      case name
        when /_Eleve_/
          parse_all_eleves(doc)
        when /_PersEducNat_/
          parse_all_pens(doc)
        when /_PersRelEleve_/
          parse_all_parents(doc)
        when /_EtabEducNat_/
          parse_etab_educ_nat(doc)
      end

      unless name =~ /_EtabEducNat_/
        find_deleted_users(doc)
      end
    end

    def init_memory_db
      #Liste de toutes les données de l'établissement
      #Présentent dans les fichiers XML
      #key : nom de la table, value : Array des Model créés
      #Nécessaire car dans un premier temps on ne touche pas à la base de données
      #Pas de create, ni de save car on doit avoir un moyen de comparer ce qu'on a réelement
      #Dans la BDD et ce qui est présent dans le fichier
      #Voila toutes les tables concernées par l'alimentation auto
      #Attention, l'ordre est important !
      @cur_etb_data = MemoryDb.new([:etablissement, :user, :regroupement, :profil_user, :telephone,
       :email, :relation_eleve, :membre_regroupement, :enseigne_regroupement])
    end
    
    def parse_etb(uai, file_list)
      #On ne parse que les établissements existants
      @cur_etb_uai = uai
      @cur_etb_xml_id = find_etb_xml_id(file_list)
      if !@cur_etb_xml_id.nil?
        init_memory_db()
        #puts "Etablissement #{@cur_etb_xml_id} avec uai #{@cur_etb_uai} present"
        if file_list.length == 4
          @cur_etb = @cur_etb_data[:etablissement].find_or_add({:code_uai => uai})
          file_list.each do |name|
            #puts "Parsing du fichier #{name}"
            parse_file(name)
          end
        else
          Ramaze::Log.error("Plus de 4 fichiers pour l'établissement #{uai} : #{file_list}")
        end
      end

      return @cur_etb_data
    end
  end
end