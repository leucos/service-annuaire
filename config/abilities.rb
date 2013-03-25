#coding: utf-8
class AdminPanelAbility < SixCan
  Ramaze::Helper::SixCan::Abilities << self
  Ramaze::Helper::SixCan::Application = App[:code => "admin_panel"]
  #app_activites = [:gestion_user_etab, :gestion_user, :app_management]
  #App.sync_activites(app_activites)
  def self.check_abilities(user)
    activites = user.activites(Ramaze::Helper::SixCan::Application)
    activites.each do |a|
      case a
        when :gestion_user_etab
          can [:create, :read, :update], User
        when :statistiques
          can :read, User
        when :activation_user
          can [:read, :update], User
          can :manage, Regroupement do |regroupement|
            regroupement.etablissement_id == user.profil_actif.etablissement_id
          end
        when :gestion_user
          can :manage, [User, Profil, ProfilUser, RoleUser, MembreRegroupement, EnseigneDansRegroupement, Regroupement]
          can :manage, Etablissement
          can :manage, App
          cannot :delete, Etablissement
        when :param_app
          can :manage, [RoleProfil, Role]
        #when :tata
      end
    end
  end
end