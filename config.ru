#!/usr/bin/env rackup
#
# config.ru for ramaze apps
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

use Rack::TryStatic,
  :root => File.expand_path('../public', __FILE__),
  :urls => %w[/], :try => ['.html', 'index.html', '/index.html']

run UserApi
run AuthApi 
run EtabApi

map "/sso" do
  run SsoApi
end

map "/" do
	run Root
end

#Ramaze.start(:root => Ramaze.options.roots, :adapter => :thin, :started => true)

#run Ramaze
