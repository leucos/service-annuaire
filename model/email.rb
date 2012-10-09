#coding: utf-8
#
# model for 'email' table
# generated 2012-04-25 15:54:20 +0200 by model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL?    | KEY      | DEFAULT    | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# adresse                       | varchar(255)        | false    |          |            | 
# principal                     | tinyint(1)          | false    |          | 1          | 
# valide                        | tinyint(1)          | false    |          | 0          | 
# academique                    | tinyint(1)          | false    |          | 0          | 
# user_id                       | char(8)             | false    | MUL      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Email < Sequel::Model(:email)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer

  # Referential integrity
  many_to_one :user

  # Not nullable cols
  def validate
    super
    validates_presence [:adresse, :user_id]
    # On ne peut avoir qu'un seul email principal
    email_principal = Email.filter(:user_id => user_id, :principal => true).first
    if email_principal and email_principal.id != id and (principal.nil? or principal)
      errors.add(:principal, "On ne peut pas avoir 2 mails principaux")
    end
  end
end
