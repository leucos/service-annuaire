require 'grape-swagger'

class Root < Grape::API
	mount UserApi
  mount EtabApi
  #mount AuthApi 
  add_swagger_documentation
end