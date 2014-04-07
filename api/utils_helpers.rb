#encoding: utf-8

module UtilsHelpers
	def check_user!(message = "Utilisateur non trouvé", param_id = :user_id)
    user = User[:id_ent => params[param_id]]
    error!(message, 404) if user.nil?
    return user
    end

  def check_email!(user)
    email = Email[:id => params[:email_id]]
    error!("Email non trouvé", 404) if email.nil? or !user.has_email(email.adresse)
    return email
  end

  def modify_user(user)
    # Use the declared helper
    declared(params, include_missing: false).each do |k,v|
      if user.respond_to?(k.to_sym)
        user.set(k.to_sym => v)
      end  
    end
    user.save()
  end
end