#!/usr/bin/env rackup
#
# Rackup is a useful tool for running Rack applications, which uses the
# Rack::Builder DSL to configure middleware and build up applications easily.
#
# Rackup automatically figures out the environment it is run in, and runs your
# application as FastCGI, CGI, or standalone with Mongrel or WEBrick -- all from
# the same configuration.
#
# Do not set the adapter.handler in here, it will be ignored.
# You can choose the adapter like `ramaze start -s mongrel` or set it in the
# 'start.rb' and use `ruby start.rb` instead.
require ::File.expand_path('../app', __FILE__)


# for the moment angular js is accesed statically
#use Rack::Static, :urls => ["/app"], :root => File.expand_path('../public/angularJS', __FILE__)


# run apis, these apis are routed using the :resource element that englobe the apis
run UserApi
run AuthApi 
run EtabApi
run ApplicationApi
run ClassApi
run AlimentationApi
run ProfilApi
map "/api/app" do
  run DocsApi
end 

map "/api/sso" do
  run SsoApi
end 

# Root maps to the documentation of the other apis
map "/" do
  run Root
end
