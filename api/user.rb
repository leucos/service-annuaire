class UserApi < Grape::API
  format :json

  get do
    u = User[:login => params[:login], :password => params[:password]]
    if u
      u
    else
      error!("Forbidden", 403)
    end
  end

  params do
    requires :login, :type => String, regexp: /^[a-z]/i, desc: "Doit commencer par une lettre"
    requires :password, :type => String
    requires :nom, :type => String
    requires :prenom, :type => String
    optional :sexe, :type => String, regexp: /^[MF]$/
    optional :date_naissance, :type => String
    optional :adresse, :type => String
    optional :code_postal, :type => Integer#, :length => 6

  end
  post do
    u = User.create(:login => params[:login], :password => params[:password], 
      :nom => params[:nom], :prenom => params[:prenom], :sexe => params[:sexe])
  end
end