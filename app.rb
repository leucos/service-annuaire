#coding: utf-8
# This file contains your application, it requires dependencies and necessary parts of 
# the application.
#
# It will be required from either `config.ru` or `start.rb`
require 'rubygems'
require 'ramaze'

# Make sure that Ramaze knows where you are
Ramaze.options.roots = [__DIR__]

require 'sequel'
require 'grape'
require 'ramaze/helper/user'
require 'i18n'
require 'date'
require 'nokogiri'
#require 'ramaze/helper/sixcan'
#require 'sequelhook'

require __DIR__('config/init')
require __DIR__('api_config')
require __DIR__('lib/auth_session')
# Initialize controllers and models
require __DIR__('lib/init')
require __DIR__('model/init')
#require __DIR__('config/abilities')
require __DIR__('helper/init')
require __DIR__('api/init')


#Rack::RouteExceptions.route(Exception,  MainController.r(:my_error_handler))




