module Ramaze
  module Helper
    module GetParam
      def get_param(code)
        param = ParamApp.where(:code => code).all

        if param.count > 1
          raise 'plusieurs parametres avec le meme code'
        elsif param.count == 0
          raise 'le parameter n\'existe pas'
        else
          return param
        end

      end

      def get_param(application_id, etablissement_id, code)
        params = ParamEtablissement.where(:param_app => ParamApp.filter(:code => code, :app_id => application_id), :etablissement_id => etablissement_id).all
        if params.count > 1
          raise 'plusieurs parametres avec le meme code'
        elsif params.count == 0
          raise 'le parameter n\'existe pas'
        else
            parametre = params.first  
            value = case parametre.param_app.type_param_id 
              when 'bool'
                to_bool(parametre.valeur)
              when 'text'
                parametre.valeur 
              when 'num'
                parametre.valeur.to_i 
              when 'msel'
                parametre.valeur.split("-")
              when 'usel'
                parametre.valeur  
            end 
            #Ramaze::Log.debug("#{value}")
            return value
        end
      end

      def get_preference(application_id, user_id , code)
        params = ParamUser.where(:param_app => ParamApp.filter(:code => code, :app_id => application_id), :user_id => user_id).all
        if params.count > 1
          raise 'plusieurs parametres avec le meme code'
        elsif params.count == 0
          raise 'le parameter n\'existe pas'
        else
            preference = params.first
            value = case preference.param_app.type_param_id 
              when 'bool'
                to_bool(preference.valeur)
              when 'text'
                preference.valeur 
              when 'num'
                preference.valeur.to_i 
              when 'msel'
                preference.valeur.split("-")
              when 'usel'
                preference.valeur  
            end 
            return value
        end  
      end

      def to_bool(string)
        return true if string == true || string =~ (/(true|t|yes|y|oui|1)$/i)
        return false if string == false || self.blank? || string =~ (/(false|f|no|n|non|0)$/i)
        raise ArgumentError.new("Boolean non valide \"#{string}\"")
      end

    end
  end
end
