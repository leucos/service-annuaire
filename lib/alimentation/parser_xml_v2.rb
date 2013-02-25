#encoding: utf-8

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
#   ENTEleveStructRattachId: user[:id_sconet]
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

# MATIERE = {
#  
# }

# MEF( module élémentaire de formation) ={
#  
#}

# require mongo db
require 'mongo'

module Alimentation
  
  # Classe d'erreur quand il manque des données pour un profil
  class MissingDataError < StandardError
  end

  # Classe utilisée quand il y a des erreurs sur les données
  class WrongDataError < StandardError
  end

  class ParserXmlMongo
    attr_accessor :db  #database
    
    # files categories or names
    CATEGORIE_ELEVE = "Eleve"
    CATEGORIE_REL_ELEVE = "PersRelEleve"
    CATEGORIE_PEN = "PersEducNat"
    
    #Todo utiliser code_men ou autre pour les profils
    PROFIL_ELEVE = "ELV"
    PROFIL_PARENT = "PAR"
    PROFIL_ENS = "ENS"

    #-----------------------------------------#
    ## Necessary method to parse xml nodes   ##
    #-----------------------------------------#
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
      return attr_list.compact
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
    #------------------------------------------------------#
    #------------------------------------------------------#
    #---------Method to compute Block exec time  ----------#
    def time(label)
      t1 = Time.now
      yield.tap{Laclasse::Log.info("%s: %.1fs" % [ label, Time.now-t1 ]) }
    end
    
    #------------------------------------------------------#
    
    #------------------------------------------------------#
    # parse user(Eleve , PersonEducationNational, Parent)  #
    #------------------------------------------------------#
     
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
          "Au moins une des données suivante est manquante nom = #{nom},  prenom = #{prenom}, id_jointure=#{id_jointure}"
          )
      end

      if identifier != id_jointure
        raise WrongDataError.new("Champs identifier (#{identifier}) et ENTPersonJointure (#{id_jointure}) différents pour #{prenom} #{nom}.") 
      end

      #L'utilisateur peut déjà avoir été créer temporairement (cas d'un enfant dont les parents sont déclarés)
      ##parsed_user = @cur_etb_data[:user].find_or_add({:id_jointure_aaf => id_jointure})
      
      ## avec mongo v2 
      ## users = users's collection 
      parsed_user = @db.collection('users').find_one({"id_jointure_aaf" => id_jointure})
      if parsed_user.nil? # user is not found
        #create user 
        id = @db.collection('users').save({"id_jointure_aaf" => id_jointure})
        #get user
        parsed_user = @db.collection('users').find_one({"_id" => id})
      end
      ##
      
      #parsed_user = @cur_etb_data[:user].push({:id_jointure_aaf => id_jointure})
      #ENTPersonDateNaissance: User[:date_naissance], #Nécessite conversion date
      
      date_naissance = get_attr(node, "ENTPersonDateNaissance")
      #puts "#{date_naissance}"
      begin
        parsed_user["date_naissance"] =  Time.parse(date_naissance)
      rescue
        if categorie == CATEGORIE_ELEVE
          raise MissingDataError.new("Date de naissance manquante pour #{prenom} #{nom} ##{id_jointure}")
        end
      end
      #   sn: User[:nom],
      parsed_user["nom"] = nom
      #   givenName: User[:prenom],
      parsed_user["prenom"] = prenom
      #   personalTitle: User[:sexe], #Nécessite conversion M. Mme. Mlle => M, F
      titre = get_attr(node, 'personalTitle')
      parsed_user["sexe"] = titre == "M." ? "M" : "F"
      #   ENTPersonAdresse: User.adresse,
      parsed_user["adresse"] = get_attr(node, "ENTPersonAdresse")
      #   ENTPersonCodePostal: User.code_postal,
      parsed_user["code_postal"] = get_attr(node, "ENTPersonCodePostal")
      #   ENTPersonVille: User.ville,
      parsed_user["ville"] = get_attr(node, "ENTPersonVille")
      #   ENTPersonPays: User.ville, #Si diffère de FRANCE
      pays = get_attr(node, "ENTPersonPays")
      parsed_user["ville"] += " #{pays}" if !parsed_user[:ville].nil? and !pays.nil? and pays != "FRANCE"
      parsed_user["date_last_maj_aaf"] = Time.now.utc   
      
      ##save user
      @db.collection("users").save(parsed_user)
      ##
      return parsed_user
    end
    
    ################################################
    ##  find person education national profil     ##
    ################################################
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

    #################################################
    ##   Add profil to user                        ##  
    #################################################
    def add_profil_to_user(user, profil_id)
      # old way with memory db
      #profil_user = {etablissement: @cur_etb, user: user, profil_id: profil_id}
      
      #new way with mongodb
      profil_user = {"etablissement" => @cur_etb_uai, "user" => user, "profil_id" => profil_id}
      profil = @db.collection('profil_user').find_one(profil_user)
      if profil.nil? # profil does not exist 
        #create profile
        id = @db.collection('profil_user').save(profil_user)
      else 
        #update profile
      end
      
      ##@cur_etb_data[:profil_user].find_or_add( 
        #{:etablissement => @cur_etb, :user => user}, profil_user)
    end
    
    ####################################################
    ## add telephone number  to user                          ##
    ####################################################
    # Pour l'instant les téléphone ne concernent que les comptes parent
    def add_phone_to_user(user, tel, default_type)
      #On cherche à savoir si c'est un portable
      if tel[0,2] == "06" or tel[0,5] == "+33 6"
        type_id = "PORT"
      else
        type_id = default_type
      end
      tel_hash = {"numero" => tel, "user" => user, "type_telephone_id" =>  type_id}
      ## maybe we can enhance the performance
      @db.collection("telephone").save(tel_hash)
    end
    
    
    ####################################################
    ##  Parse Regroupement                            ##
    #  @Args
    #   - +node+ -> Xml node that represent the Eleve
    #   - +user+ -> hash of eleve info 
    #  @Returns
    #   - parse regroupements
    #  @Raises
    #   - nothing  
    ####################################################      
    #Parse les rattachements à un regroupement pour les profs et les élèves
    def parse_regroupement(node, attr_name, type_reg_id, user, matiere_list=nil)
      reg_list = get_multiple_attr_etb(node, attr_name)
      #pp reg_list

      if type_reg_id == "CLS" and reg_list.length > 1 and matiere_list.nil?
        raise WrongDataError.new("L'élève #{user} a plusieurs classes renseignées pour le même établissement.")
      end

      reg_list.each do |libelle_aaf|
        #Les fichiers xml ne nous fournissent pas la liste des différents classes et groupes de l'établissement
        #on doit donc la créer nous même à partir des rattachements d'élève et de prof
        reg = @db.collection("regroupement").find_one({"etablissement"=> @cur_etb_uai, 
          "libelle_aaf"=> libelle_aaf, "type_regroupement_id"=> type_reg_id})
          
        if !reg 
          reg_id = @db.collection("regroupement").save({"etablissement"=> @cur_etb_uai, 
          "libelle_aaf"=> libelle_aaf, "type_regroupement_id"=> type_reg_id})
          reg = @db.collection("regroupement").find_one({"_id"=> reg_id})
        end
        
        
        #Le libellé par défaut est le libellé aaf
        reg["libelle"] = libelle_aaf if reg["libelle"].nil?

        #Les classes ont un niveau
        if type_reg_id == "CLS"
          niv_lib = get_attr(node, "ENTEleveLibelleMEF")
          #niveau = DB[:niveau].filter(:libelle => niv_lib).first
          #niveau = DB[:niveau].first if niveau.nil?
          #reg["niveau_id"] = niveau[:id]
          
          #v2 ithink transformation here is not necessary
          reg["niveau_id"] = niv_lib
        end
        @db.collection("regroupement").save(reg)

        #Si pas de matière enseignée il s'agit d'un élève
        if matiere_list.nil?
          found = @db.collection("membre_regroupement").find_one({"regroupement" => reg, "user" => user})
          if found.nil?
            @db.collection("membre_regroupement").save({"regroupement" => reg, "user" => user})
          end 
        
        else #Sinon d'un prof
          #ENTAuxEnsClassesPrincipal: EnseigneRegroupement.prof_principal
          classes_principal = get_multiple_attr_etb(node, "ENTAuxEnsClassesPrincipal")
          prof_principal = false
          classes_principal.each { |cls_code| prof_principal = true if cls_code == libelle_aaf }
          # On a juste une liste de matière enseignée pour le professeur
          # mais on ne sait pas quelle matière est enseignée dans quelle classe.
          # Donc on met toutes les matières sur toutes les classes.
          matiere_list.each do |mat_id|
            found = @db.collection("enseigne_regroupement").find_one({"regroupement" => reg, "user" => user, "matiere_enseignee_id" => mat_id, 
                "prof_principal" => prof_principal})
            if found.nil?
              @db.collection("enseigne_regroupement").save({"regroupement" => reg, "user" => user, "matiere_enseignee_id" => mat_id, 
                "prof_principal" => prof_principal})
            end 
          end
        end
      end
    end
    
    #--------------------------------------------------#
    #  Add Relation Eleve                             ##  
    #  @Args
    #   - +eleve+ -> hash containg eleve information
    #   - +adulte_id+ -> the id of the adulte in the relation with the eleve
    #   - +type_rel_id+ -> type of the relation (pere, mere, etc ..)
    #   - resp_financier, resp_legal, contact, paiement -> new annauire
    #   - +add_profil_parent  => if the adulte is the parent
    #  @Returns
    #   - modify data structure and add relations to the Eleve 
    #  @Raises
    #   - nothing
    #  @todo check other profils than parents
    #---------------------------------------------------#
    def add_relation_eleve(eleve, adulte_id, type_rel_id,resp_financier, resp_legal, contact, paiement, add_profil_parent = false)
      adulte = @db.collection("users").find_one({"id_jointure_aaf" => adulte_id})
      if adulte.nil?
        id = @db.collection("users").save({"id_jointure_aaf" => adulte_id})
        adulte = @db.collection("users").find_one({"id_jointure_aaf" => adulte_id})
      end
      # todo : peut-etre qu'il faut pouvoir cumuler les relations avec l'élève ?
      # ex : Représentant légal et Responsable Financier ?
      #relation = {"user" => adulte, "eleve" => eleve,"type_relation_eleve_id" => type_rel_id }
      
      #save relation to database
      found = @db.collection("relation_eleve").find_one({"user"=> adulte, "eleve"=> eleve})
      if found 
          @db.collection("relation_eleve").update({"user"=> adulte, "eleve"=> eleve}, {"$set" => 
            {"type_relation_eleve_id" => type_rel_id, "resp_financier"=> resp_financier,
             "resp_legal"=> resp_legal, "contact"=> contact, "paiement" => paiement}})
      else 
          relation_id = @db.collection("relation_eleve").save({"user" => adulte, "eleve" => eleve,"type_relation_eleve_id" => type_rel_id, 
            "resp_financier"=> resp_financier, "resp_legal"=> resp_legal, "contact"=> contact, "paiement" => paiement})
      end 

      add_profil_to_user(adulte, PROFIL_PARENT) if add_profil_parent
    end    
    
    #--------------------------------------------------#
    ##  Parse Relation Eleve                          ##
    #  @Args
    #   - +node+ -> Xml node that represent the Eleve
    #   - +eleve+ -> hash of eleve info 
    #  @Returns
    #   - parse relation with the eleve
    #  @Raises
    #   - nothing
    #---------------------------------------------------#  
    def parse_relation_eleve(node, eleve)
      # find all relation with eleve version  only need to parse ENTElevePersRelEleve attribute  
      rel = get_multiple_attr(node,"ENTElevePersRelEleve")
      relations_hash = rel.map do |relation|
          split_array = relation.split('$')
          {"cle_jointure_person"=> split_array[0].to_i,"type_relation"=>split_array[1].to_i,
            "resp_legal" => split_array[3].to_i, "resp_financier"=>split_array[2].to_i, 
            "contact" => split_array[4], "paiement"=>split_array[5]}
      end
      
      #pp relations_hash
       
      relations_hash.each do |relation|
        add_relation_eleve(eleve, relation["cle_jointure_person"], relation["type_relation"], 
          relation["resp_financier"], relation["resp_legal"], relation["contact"],
          relation["paiement"], relation["type_relation"] == 1 || relation["type_relation"] == 2 ? true : false)
      end
    end
    
    
    #-------------------------------------------#
    ##    Parse Eleve                          ##
    #  @Args
    #   - +node+ -> Xml node that represent the Eleve
    #   - +eleve+ -> hash of eleve info 
    #  @Returns
    #   - add sconet_id to the eleve, add profil to eleve 
    #   - parse relation with the eleve, and regroupements
    #  @Raises
    #   - MissingDataError if ENTEleveStructRattachId(sconet id) is not found
    #   - MissingDataError if ENTPersonStructRattach is not found
    #--------------------------------------------#
    def parse_eleve(node, eleve)
      #Parsing specific à l'élève
      #   ENTEleveStructRattachId
      eleve["id_sconet"] = get_attr(node, "ENTEleveStructRattachId", :int)
      if eleve["id_sconet"].nil?
        raise MissingDataError.new("ENTEleveStructRattachId (id sconet) manquant pour l'élève #{eleve}")
      end

      # ENTPersonStructRattach: ProfilUser.etablissement_id, #Nécessite conversion id=>UAI
      # La structure de rattachement n'est pas forcément l'établissement
      # actuellement parsé
      struct_rattach = get_attr(node, 'ENTPersonStructRattach')
      if struct_rattach.nil?
        raise MissingDataError.new("Structure de rattachement manquante pour l'élève #{eleve}")
      end
      
      ## save changes to eleve
      @db.collection("users").save(eleve)

      # add profile to eleve
      add_profil_to_user(eleve, PROFIL_ELEVE)
     
      # Gestion des relations élève (parents, correspondants etc)
      parse_relation_eleve(node, eleve)

      #   ENTEleveClasses: MembreRegroupement, #Faire le liens entre libelle_aaf et id interne
      # todo : gérer les codes mef de la classe et le niveau
      parse_regroupement(node, "ENTEleveClasses", "CLS", eleve)
      #   ENTEleveGroupes: MembreRegroupement #Idem
      parse_regroupement(node, "ENTEleveGroupes", "GRP", eleve)
    end

    #-----------------------------------------------#
    ##  Parse Eleves Xml Files                     ##   
    #-----------------------------------------------#
    def parse_all_eleves(xml_doc)
      count = 0
      xml_doc.css("addRequest, modifyRequest").each do |node|
        begin
          count+=1 
          eleve = parse_user(node, CATEGORIE_ELEVE)
          parse_eleve(node, eleve) unless eleve.nil?
        rescue => e
          #add error to database
          @db.collection("error").save({"origin" => "eleve","message"=> e.message}) 
          Laclasse::Log.error(e.message)
        end  
      end
      Laclasse::Log.info("number of treated eleves = #{count}")
    end

    #-------------------------------------------#
    ##  Parse Enseignant                       ##   
    #-------------------------------------------#
    def parse_enseignant(node, enseignant)
      
      ## Parse mail 
      # N'existe que pour les prof et le mail académique
      adresse = get_attr(node, "mail")
      unless adresse.nil?
        email_hash = {"adresse" => adresse, "user" => enseignant}
        email_hash["academique"] = true if adresse.index(/@ac-.*\.fr/)
        found = @db.collection("email").find_one(email_hash)
        if found.nil?
           @db.collection("email").save(email_hash)
        end
      end

      ##  ENTAuxEnsMatiereEnseignEtab: EnseigneRegroupement.matiere_enseignee_id
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
            m = MatiereEnseignee.create(:id => new_id, :libelle_long => mat,
              :libelle_edition => mat, :famille_matiere_id => 0)
            Laclasse::Log.info("Matière #{mat} inconnue nouvel id #{m.id}")
          end
          id = m.id unless m.nil?
        end
        #   ENTAuxEnsClasses: EnseigneRegroupement.regroupement_id
        parse_regroupement(node, "ENTAuxEnsClasses", "CLS", enseignant, matiere_list)
        #   ENTAuxEnsGroupes: EnseigneRegroupement.regroupement_id
        parse_regroupement(node, "ENTAuxEnsGroupes", "GRP", enseignant, matiere_list)
      end
    end

    #-------------------------------------------#
    ##  parse personel education national      ##   
    #-------------------------------------------#
    def parse_pen(node, pen)
      profil_id = find_pen_profil_id(node, pen)
      #[debug]
      add_profil_to_user(pen, profil_id)
      #[debug]
      #pp @db.collection("profil_user").find_one({"user" => pen})
      
      #  PersEducNatPresenceDevantEleves: permet de savoir si oui ou non une personne est prof
      enseigne = get_attr(node, "PersEducNatPresenceDevantEleves")
      if !pen.nil? and enseigne == 'O'
        parse_enseignant(node, pen)
      end
    end

    #-------------------------------------------#
    ##  parse all personel education national  ##   
    #-------------------------------------------#
    def parse_all_pens(xml_doc)
      count = 0
      xml_doc.css("addRequest, modifyRequest").each do |node|
        begin
          count += 1
          pen = parse_user(node, CATEGORIE_PEN)
          parse_pen(node, pen)
        rescue => e 
          @db.collection("error").save({"origin" => "person education national", "message"=> e.message})
          Laclasse::Log.error(e.message)
        end 
      end
      #log info of treated requests
      @statstic['count_pen'] = count
      Laclasse::Log.info("number of treated personel education national =  #{count}") 
    end


    #-------------------------------------------#
    ##  parse relation eleve                   ##   
    #-------------------------------------------#
    
    def parse_pers_rel_eleve(node, pers_rel_eleve)
      #   homePhone: Telephone.numero
      #a noter qu'il ne s'agit pas forcément du téléphone de la maison
      #donc on check si c'est un portable au cas où...
      #Ah spielberg...
      telephone_maison = get_attr(node, "homePhone")
      add_phone_to_user(pers_rel_eleve, telephone_maison, "MAIS") unless telephone_maison.nil?
      #   telephoneNumber: Telephone.numero,
      tel = get_attr(node, "telephoneNumber")
      add_phone_to_user(pers_rel_eleve, tel, "AUTR") unless tel.nil?
      # Spécifique au SDET V4 donc pas encore là
      mobile = get_attr(node, "mobile")
      add_phone_to_user(pers_rel_eleve, mobile, "PORT") unless mobile.nil?
    end

    #-------------------------------------------#
    ##  parse all relation eleve               ##   
    #-------------------------------------------#
    def parse_all_pers_rel_eleve(xml_doc)
      count = 0 
      xml_doc.css("addRequest, modifyRequest").each do |node|
        begin
          count +=1 
          pers_rel_eleve = parse_user(node, CATEGORIE_REL_ELEVE)
          parse_pers_rel_eleve(node, pers_rel_eleve)
        rescue => e 
          @db.collection("error").save({"origin" => "Relation Eleve", "message"=> e.message, "type" =>"waring or error"})
          Laclasse::Log.error(e.message)
        end 
      end
      #log info of treated requests
      @statstic['count_pers_rel_eleve'] = count
      Laclasse::Log.info("number of treated relations #{count}") 
    end


    #-------------------------------------------#
    ##  parse etablissement education national ##   
    #-------------------------------------------# 
 
    def parse_etab_educ_nat(xml_doc)
      
      #TODO créer les établissements quand ils n'existent pas ?
      count = 0  # holds the number of treated records
      xml_doc.css("addRequest, modifyRequest").each do |node|
        count+=1 #
        #get id Etablissement which is different from UAI
        #This id will facilitate the research to find the UAI
        id_jointure = get_attr(node, 'ENTStructureJointure')
        uai = get_attr(node, 'ENTEtablissementUAI')
        etb = @db.collection("etablissement").find_one({"code_uai"=> uai})
        if etb.nil? # create one 
          id = @db.collection("etablissement").save({"code_uai"=> uai})
          etb = @db.collection("etablissement").find_one({"_id"=> id})
        end
        
        etb["structure_jointure"] = id_jointure 
        etb["siren"] = get_attr(node, 'ENTStructureSIREN')
        #Le nom est apparement toujours sous cette forme
        # TYPE DE STRUCTURE-NOM DE L'ETAB-ac-lyon
        nom_complexe = get_attr(node, 'ENTStructureNomCourant')
        nom_decoupe = nom_complexe.split('-')
        #Attention ce n'est pas spécifié dans le SDET alors on se méfit
        if nom_decoupe.length > 1
          etb["nom"] = nom_decoupe[1]
        else
          etb["nom"] = nom_complexe
        end

        etb["adresse"] = get_attr(node, 'street')
        etb["code_postal"] = get_attr(node, 'postalCode')
        
        #todo : gérer la commune avec une table externe et trouver une solution pour les boites postales ?
        etb["ville"] = get_attr(node, 'l')
        boite_postale = get_attr(node, 'postOfficeBox')
        etb["ville"] += " BP #{boite_postale}" unless boite_postale.nil?
        etb["telephone"] = get_attr(node, 'telephoneNumber')
        etb["fax"] = get_attr(node, 'facsimileTelephoneNumber')

        #Création du type d'établissement à la volé s'il le faut
        type_nom = get_attr(node, 'ENTStructureTypeStruct')
        type_contrat = get_attr(node, 'ENTEtablissementContrat')
        type_etab = {"nom" => type_nom, "type_contrat" => type_contrat}
        type_etab_model = TypeEtablissement.find_or_create(type_etab)

        etb["type_etablissement_id"] = type_etab_model.id
        @db.collection("etablissement").save(etb)
      end
      #add count to statstics
      @statstic['count_etabs'] = count
      
      #log info of treated requests
      Laclasse::Log.info("number of treated Etabilssement #{count}") 
    end
    
    #-------------------------------------------#
    ##  find deleted files                     ##   
    #-------------------------------------------# 
    def find_deleted_users(xml_doc)
      xml_doc.css("deleteRequest").each do |node|
        deleted_user_id = node.at_css("identifier id")
        unless deleted_user_id.nil?
          deleted_user_id = deleted_user_id.content.to_i
          #Petit hack : on rajout un user avec le flag deleted
          #diff_generator sait alors qu'il faut le supprimer de l'établissement
          found = @db.collection("users").find_one({"id_jointure_aaf"=>deleted_user_id})
          if !found.nil?
            @db.collection("users").update({"id_jointure_aaf"=>deleted_user_id}, {"$set" => {"deleted"=>true}})
          end 
        end
      end
    end
 
    #-------------------------------------------#
    #   parse Xml File                          #   
    #-------------------------------------------#
    def parse_file(name)
      time("File parsing Time") do 
        #start = Time.now
        f = File.open(name)
        doc = Nokogiri::XML(f)
  
        case name
          when /_Eleve_/
            parse_all_eleves(doc)
          when /_PersEducNat_/
            parse_all_pens(doc)
          when /_PersRelEleve_/
            parse_all_pers_rel_eleve(doc)
          when /_EtabEducNat_/
            parse_etab_educ_nat(doc)
          when /_MatiereEducNat_/
            Laclasse::Log.info("parse matiers disactivé")
          when /_MefEducNat_/
            Laclasse::Log.info("parse MEF disactivé")
        end
  
        unless name =~ /_EtabEducNat_/
          find_deleted_users(doc)
        end
        #fin = Time.now
        #Laclasse::Log.info("file parsing took #{fin-start} seconds") 
      end
    end

    #-------------------------------------------#
    #  initialize data base (mongo db)          #   
    #-------------------------------------------#
    def init_memory_db(config)
      #Liste de toutes les données de l'établissement
      #Présentent dans les fichiers XML
      #Voila toutes les tables concernées par l'alimentation auto
      #Attention, l'ordre est important !
      ## new way db connection
      #drop data base if exists
      begin  
        Mongo::Connection.new(config[:server],config[:port] || 27017).drop_database(config[:db])
        @db = Mongo::Connection.new(config[:server],config[:port] || 27017).db(config[:db])
        @statstic = {} # a hash that contains statistics$
        #Adding indexes for database
        @db.collection("etablissement").create_index("id_jointure_aaf")
        @db.collection("users").create_index("id_jointure_aaf")
      rescue
         Laclasse::Log.error("Mongo db connection error") 
      end 
      
      # @db contains the following ocnnections
      # etablissement, users, regroupement, profil_user, telephone,
      # email, relation_eleve, membre_regroupement, enseigne_regroupement,
      # and we have to process the matiere separatley.
    end
    
    #-------------------------------------------#
    #   parse files per etablissement           #   
    #-------------------------------------------#
    def parse_etb(uai, file_list)
      #On ne parse que les établissements existants
      time("Total etablissement #{uai} parsing time") do 
        @cur_etb_uai = uai
        @cur_etb_xml_id = find_etb_xml_id(file_list)
        config = {:server => "localhost", :db => "mydb"}
        if !@cur_etb_xml_id.nil?
          ## refactoring
          init_memory_db(config)
          
          #puts "Etablissement #{@cur_etb_xml_id} avec uai #{@cur_etb_uai} present"
          if file_list.length >= 4 && file_list.length <= 6
            @cur_etb = @db.collection("etablissement").find_one({"code_uai" => uai})
            if @cur_etb.nil?
              id = @db.collection("etablissement").save({"code_uai" => uai})
              @cur_etb = @db.collection("etablissement").find_one({"_id" => id})
            end
            file_list.each do |name|
              Laclasse::Log.info("Parsing du fichier #{name}")
              parse_file(name)
            end
          else
            Laclasse::Log.error("Plus de 4 fichiers pour l'établissement #{uai} : #{file_list}")
          end
        end
        # im not sure if we have to return something
      end #time 
    end 
    
    #----------------------------------------------#
    # Parse All Etablissement
    # @input: etb_file_map => a hash that contains files 
    # classified by etablissement 
    #----------------------------------------------#
    def parse_all_etb(etb_file_map)
      etb_file_map.each do |uai, file_list|
        begin
          Laclasse::Log.info("Start parsing etablissement #{uai}")
          #
          parse_etb(uai, file_list)
          
          # Statistics of parsing (may be this need another class)
          puts "------Statistics of parsing -----------\n"
          puts "users = #{@db.collection("users").count} \n"
          puts "etablissement = #{@db.collection("etablissement").count}\n"
          puts "relation_eleve = #{@db.collection("relation_eleve").count}\n"
          puts "regroupement = #{@db.collection("regroupement").count}\n"
          #regroupement, profil_user, telephone,
          # email, relation_eleve, membre_regroupement, enseigne_regroupement
          # Error Generation
        rescue => e
          @db.collection("error").save({"origin" => "Etablissement", "message"=> e.message, "type" =>"waring or error"})
          puts "Erreur lors de l'alimentation de l'établissement #{uai}"
          puts "#{e.message}"
          #puts "#{e.backtrace}"
        end
      end
    end
  end #end class
end #end module