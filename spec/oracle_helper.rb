#coding: utf-8

#
# Helper pour les specs utilisant les models Oracle
#
module Ora
  def self.get_last_uid_ldap
    # Dans certains cas, les uid peuvent être null ou pas valide
    u = Utilisateur.exclude(:uid_ldap => nil).
      filter(Sequel.char_length(:uid_ldap) => 8).
      filter(:uid_ldap.like('V__6%')).
      order(:uid_ldap).last
    return u.uid_ldap
  end

  # Créer juste un utilisateur de test avec des propriétés spécifiques
  def self.create_user(login = "test")
    last_uid = get_last_uid_ldap()
    next_uid = LastUid.increment_uid(last_uid)
    puts "last_uid=#{last_uid} next_uid=#{next_uid}"
    #seq_id = :nextval.qualify(:user_seq)
    Utilisateur.create(:nom => "test", :prenom => "test", :uid_ldap => next_uid,
      :login => login, :pwd => "test", :date_creation => Time.now)
  end

  # Ajoute un profil dans utilisateur_info si c'est le premier
  # Puis dans liste_config_utilisateur si c'est pas le premier
  def self.user_add_profil(user, etab_id, profil_id)
  end

  def self.user_add_parent(user, parent)
  end

  def self.prof_add_classe(prof, classe, mat_id)
  end

  def self.prof_add_groupe_eleve(prof, groupe)
  end

  def self.eleve_set_classe(eleve, classe)
  end

  def self.eleve_add_groupe_eleve(eleve, groupe)
  end

  def self.user_add_groupe_libre(user, groupe, role)
  end

  def self.create_test_etab(type_etab_id)
  end

  def self.etab_create_classe(etab_id, niveau_id)
  end

  def self.etab_create_groupe_eleve(etab_id)
  end

  def self.create_groupe_libre
  end
end