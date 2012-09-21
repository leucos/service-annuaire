class Annuaire
  include Ramaze::Optioned

  options.dsl do
    # Ne va-t-on finalement pas faire cela différement ?
    o "Actions list on which access is restricted to specific url", :restricted_actions, 
      {
        'UserController' => {
          :get_sso_attributes => ["192.168.0.11", "127.0.0.1"],
          :get_sso_attributes_men => ["192.168.0.11", "127.0.0.1"]
        }
      }

    o "Current application", :current_app, 'annuaire' # Utile pour SixCan ?
  end
end