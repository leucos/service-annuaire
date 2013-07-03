class DocsApi < Grape::API
  format :json
  helpers RightHelpers
  rescue_from :all

  before do
    #authenticate_app!
  end

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
				error!("resource non trouvee") 
			end  
		end
  
end #class