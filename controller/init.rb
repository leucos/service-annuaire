#coding: utf-8
# Define a subclass of Ramaze::Controller holding your defaults for all controllers. Note 
# that these changes can be overwritten in sub controllers by simply calling the method 
# but with a different value.

class Controller < Ramaze::Controller
  layout :default
  helper :xhtml, :user

  #Certaines action ont un acces restrint, on vérifie donc si l'action en cours
  #est dans ce cas et si oui, si l'appelant fait bien parti de la liste des personnes
  #authorisées.
  def restrict_access
    restricted_controller = Annuaire.options.restricted_actions[action.node.to_s]
    unless restricted_controller.nil?
      restricted_action = restricted_controller[action.method.to_sym]
      unless restricted_action.nil?
        if restricted_action.index(request.env["REMOTE_ADDR"]).nil?
          redirect_referrer
         end
      end
    end
  end

  before_all do
    restrict_access
    # Les choses vont se passer différement avec l'api d'authentification
    #Init current user with the cas attributs
    #cas_attr = request.env['rack.session'][:cas] 
    #cas_attr = {:user => 'basharrsrrersesfes'}
    #user_login(cas_attr)
  end
end

#require __DIR__('user')