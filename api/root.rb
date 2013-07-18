require 'grape-swagger'

class Root < Grape::API
  #prefix 'api'
  mount UserApi
  mount EtabApi
  mount AuthApi 
  mount AlimentationApi
  mount ApplicationApi
  mount ClassApi
  mount ProfilApi
  mount RoleApi
  add_swagger_documentation
end