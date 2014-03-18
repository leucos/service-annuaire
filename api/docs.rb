require_relative '../lib/auth_api'

class DocsApi < Grape::API
  format :json
  helpers RightHelpers
  rescue_from :all

  before do
    authenticate_app!
  end

  ##############################################################################
  get '/' do 
    "found"
  end    
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
    #authorize_activites!(ACT_READ,etab.ressource)
    # construct etablissement entity.
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
  desc "search user return user info"
  params do 
    requires :etablissement, type:String
    requires :nom, type:String
    requires :prenom, type:String
    optional :data_de_naissance
  end 
  get "/users" do
    puts "here"
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
  desc "return users's ids for which a user is responsable"
  params do 
    requires :id, type:String
  end
  get "users/:id/responsableOf" do
    user = User[:id_ent => params[:id]]
    if !user.nil?
      user.responsableOf
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
  desc "api de test"
  get "/signed" do 
    
    puts "Authenticated"
    puts AuthApi.authenticate(request) 
 
  end

  ##############################################################################
  desc " retourner la listed des profils  dans laclasse"
  get "/profils" do
    Profil.naked.all
  end
end #class