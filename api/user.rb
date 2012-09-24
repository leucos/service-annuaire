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
end