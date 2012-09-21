#coding: utf-8

class UserController < Controller
  def index
    login = request.params["login"]
    pass = request.params["password"]
    if login and pass
      u = User[:login => login, :password => pass]
      if u
        return u.to_json
      else
        respond("error",status = 403)
      end
    end
    respond("error",status = 403)
  end
end