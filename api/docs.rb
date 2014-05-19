require_relative '../lib/auth_api'

class DocsApi < Grape::API
  format :json
  helpers RightHelpers
  helpers UtilsHelpers
  rescue_from :all

  before do
    authenticate_app!
  end
  ##############################################################################
  desc "get the list of etablissements"
  get "/etablissements" do
    ds = DB[:etablissement]
    #dataset = ds.all
    dataset = Etablissement.dataset
    dataset.select(:id, :code_uai, :nom).naked
  end
  ##############################################################################
  desc "Get etablissement info"
  params do
    requires :uai, type: String
    optional :expand, type:String, desc: "show simple or detailed info, value = true or false"
  end  
  get "/etablissements/:uai" do
    etab = Etablissement[:code_uai => params[:uai]]
    if !etab.nil?
      if params[:expand] == "true"
        present etab, with: API::Entities::DetailedEtablissement
      else
        present etab, with: API::Entities::SimpleEtablissement
     end
    else
      error!("ressource non trouve", 404)
    end
  end
  ##############################################################################
   desc "list all regroupements  in the etablissement"
  params do
    requires :uai, type: String
  end
  get "/etablissements/:uai/regroupements" do
    etab = Etablissement[:code_uai => params[:uai]]
    error!("ressource non trouvee", 404) if etab.nil?
    begin
      JSON.pretty_generate ({
        classes: etab.classes,
        groupes_eleves: etab.groupes_eleves,
        groupes_libres: etab.groupes_libres
      })
    rescue => e
      error!("mouvaise requete", 400)
    end
  end

  ##############################################################################
  desc "list all classes in the etablissement"
  params do
    requires :uai, type: String
  end
  get "/etablissements/:uai/classes" do
    etab = Etablissement[:code_uai => params[:uai]]
    error!("ressource non trouvee", 404) if etab.nil?
    begin
      JSON.pretty_generate(etab.classes)
    rescue => e
      error!("mouvaise requete", 400)
    end
  end
  ##############################################################################
  desc "lister les groupes eleves dans l\'etablissement"
  params do
    requires :uai, type:String
  end
  get "/etablissements/:uai/groupes" do
    etab = Etablissement[:code_uai => params[:uai]]
    error!("ressource non trouvee", 404) if etab.nil?
    JSON.pretty_generate(etab.groupes_eleves)
   end
  ###############################################################################
  # pour l'instant les apis concernant les groupes libres son attachés à un etablissement
  # peut-etre on va les separer àpres.
  desc "listre les groupes libres dans un etablissement"
  params do
    requires :uai, type: String
  end
  get "/etablissements/:uai/groupes_libres" do
    etab = Etablissement[:code_uai => params[:uai]]
    error!("ressource non trouvee", 404) if etab.nil?
    etab.groupes_libres
  end
  ###############################################################################
  desc "lister les matieres dans un etablissement"
  params do 
    requires :uai, type:String
  end
  get "/etablissements/:uai/matieres" do
    etab = Etablissement[:code_uai => params[:uai]]
    error!("ressource non trouvee", 404) if etab.nil?
    JSON.pretty_generate(etab.matieres)
  end
  ###############################################################################
  desc "search user return user info"
  params do
    requires :etablissement, type:String
    requires :nom, type:String
    requires :prenom, type:String
    optional :data_de_naissance
  end
  get "/users" do
    users = User.join(:profil_user, :user_id => :user__id).join(:etablissement, :etablissement__id => :etablissement_id).naked
    .filter(:user__nom => params[:nom].capitalize, :user__prenom => params[:prenom].capitalize, :etablissement__code_uai => params[:etablissement]).select(:id_ent)
    if users.empty?
      error!("ressource non trouve", 404)
    elsif (users.count == 1)
      users
    else
      error!("plusieurs utilisateurs ont ete trouves")
    end
  end
  ##############################################################################
  desc "return user information"
  params do
    requires :id, type:String
  end
  get "/users/:id" do
      user = User[:id_ent => params[:id]]
      if !user.nil?
        if params[:expand] == "true"
          present user, with: API::Entities::DetailedUser
        else
          present user, with: API::Entities::SimpleUser
        end 
      else
        error!("resource non trouvee", 404)
      end  
  end
  #############################################################################
  desc "retourner les regroupements d'un utilisateurs"
  params do
    requires :id, type: String
  end
  get "/users/:id/regroupements" do
    user = User[:id_ent => params[:id]]
    if !user.nil?
      JSON.pretty_generate({
        classes: user.classes_display,
        groupes_eleves: user.groupes_display,
        groupes_libres: user.groupes_libres
        })
    else
      error!("resource non trouvee", 404)
    end
  end
  #############################################################################
  desc "retourner les classes d'un  utilisateur"
  params do
    requires :id, type: String
  end
  get "/users/:id/classes" do
    user = User[:id_ent => params[:id]]
    if !user.nil?
      user.classes_display
    else
      error!("resource non trouvee", 404)
    end
  end
  #############################################################################
  desc "retourner les groupes eleves d'un  utilisateur"
  params do
    requires :id, type: String
  end
  get "/users/:id/groupes" do
    user = User[:id_ent => params[:id]]
    if !user.nil?
      user.groupes_display
    else
      error!("resource non trouvee", 404)
    end
  end
  #############################################################################
  desc "retourner les groupes eleves d'un  utilisateur"
  params do
    requires :id, type: String
  end
  get "/users/:id/groupes_libres" do
    user = User[:id_ent => params[:id]]
    if !user.nil?
      user.groupes_libres
    else
      error!("resource non trouvee", 404)
    end
  end
  #############################################################################
  desc "Modification d'un compte utilisateur"
  params do
    optional :login, type: String, desc: "Doit commencer par une lettre et ne pas comporter d'espace"
    optional :password, type: String
    optional :nom, type: String
    optional :prenom, type: String
    optional :sexe, type: String, desc: "Valeurs possibles : F ou M"
    optional :date_naissance, type: Date
    optional :adresse, type: String
    optional :code_postal, type: Integer, desc: "Ne doit comporter que 6 chiffres"
    optional :ville, type: String
    optional :bloque, type:Boolean
  end
  put "/users/:user_id" do
    user = check_user!()
    modify_user(user)
    present user, with: API::Entities::SimpleUser
  end
  #############################################################################
  desc "Retourner la liste des applications d'un utilisateur"
  params do
    requires :id, type:String
  end
  get "/users/:id/applications" do
    user = User[:id_ent => params[:id]]
    if !user.nil?
      user.applications
    else
      error!("resource non trouvee", 404)
    end
  end
  #############################################################################
  desc "return A list of user informations" 
  params do 
    requires :ids, type:String
  end 
  get "/users/liste/:ids" do   
    begin
      ids_array = params[:ids].split(';')
      liste = []
      ids_array.each  do |id|
        user = User[:id_ent => id]
        puts user 
        if user
          liste.push({id_ent:id, nom:user.nom, prenom:user.prenom, full_name:user.full_name})
        end 
      end
      # return only uniq elements
      liste.uniq 
    rescue => e
      error!("mouvaise requete", 404)
    end 
  end
  #############################################################################
  desc "return a list of user informations"
  params do 
    requires :ids, type:String
  end
  post "/users/liste" do
    begin
      ids_array = params[:ids].split(';')
      liste = []
      ids_array.each  do |id|
        user = User[:id_ent => id]
        puts user 
        if user
          liste.push({id_ent:id, nom:user.nom, prenom:user.prenom, full_name:user.full_name})
        end 
      end
      # return only uniq elements
      liste.uniq 
    rescue => e
      error!("mouvaise requete", 404)
    end
  end
  ##########################################################################Net::HTTP.get(URI.parse(url))####
  desc "return matiere id for libelle long"
  params do 
    requires :libelle, type:String
  end 
  get "/matieres/libelle/:libelle",requirements: { libelle: /.*/ }  do 
    matiere = MatiereEnseignee[:libelle_long => params[:libelle].upcase]
    if matiere 
      matiere
    else
      error!("ressource non trouve", 404)
    end
  end  

  desc " return matiere information"
  params do 
    requires :matiere_id, type:String
  end 
  get "/matieres/:matiere_id", requirements: { matiere_id: /.*/ } do 
    matiere = MatiereEnseignee[:id => params[:matiere_id]]
    if matiere
      matiere 
    else
      error!("ressource non trouve", 404)
    end 
  end


  ##############################################################################
  desc "return all matieres"
  get "/matieres" do 
    MatiereEnseignee.naked.all
  end 


  #eleve_id         # en fonction de (etablissement, nom, prénom, sexe,
    #date_de_naissance)
  #enseignant_id    # en fonction de (etablissement, nom, prénom)
  #matiere_id       # en fonction de (établissement, code, libellé)
  #regroupement_id  # en fonction de (établissement, nom)

  ##############################################################################
  desc "return regroupement id if exist"
  params do 
    requires :etablissement, type:String 
    requires :nom, type:String
  end  
  get "/regroupements" do 
    regroupements = Regroupement.join(:etablissement, :etablissement__id => :etablissement_id).naked
    .filter(:libelle_aaf=>params[:nom].upcase, :code_uai=> params[:etablissement]).select(:regroupement__id)
    
    if regroupements.empty?
      error!("ressource non trouve", 404)
    elsif (regroupements.count == 1)
      regroupements 
    else
      error!("Plusieurs ressources trouvees", 404)
    end
  end 

  ##############################################################################
  desc "return regroupement info "
  params do 
    requires :id, type:Integer
  end 
  get "/regroupements/:id" do 
    regroupement = Regroupement[:id => params.id]
    if regroupement
      if params[:expand] == "true"
        present regroupement, with: API::Entities::DetailedRegroupement
      else 
        present regroupement, with: API::Entities::SimpleRegroupement
      end
    else 
      error!("ressource non trouve", 404)
    end 
  end
  ##############################################################################
  desc "Upload an avatar"
  params do
    requires :user_id, type:String
    requires :image
  end
  post "/users/:user_id/upload/avatar" do
    user = User[id_ent => params[:user_id]]
    if user
      tempfile = params[:image][:tempfile]
      imagetype = params[:image][:type].split("/")[1]
      # add avatar name to database if neaded
      uploader = ImageUploader.new
      # delete old avatar
      user.remove_avatar!
      user.avatar = params[:image]
      user.save
      {
        user: params[:id],
        filename: user.avatar,
        size: tempfile.size,
        type: imagetype
      }
    else
      error!("utilisateur non trouve", 404)
    end
  end
  ##############################################################################
  desc " retourner la listed des profils  dans laclasse"
  get "/profils" do
    Profil.naked.all
  end
end #class