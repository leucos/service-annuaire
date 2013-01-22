#coding: utf-8
# This file contains your application, it requires dependencies and necessary parts of 
# the application.
#
# It will be required from either `config.ru` or `start.rb`
require 'rubygems'

require 'sequel'
require 'grape'
require 'i18n'
require 'date'
require 'nokogiri'
require 'securerandom'
require 'redis'
require 'mail'
require 'bcrypt'
require 'logger'

def __DIR__(*args)
  filename = caller[0][/^(.*):/, 1]
  dir = File.expand_path(File.dirname(filename))
  ::File.expand_path(::File.join(dir, *args.map{|a| a.to_s}))
end

require __DIR__('lib/laclasse')
require __DIR__('config/init')
require __DIR__('lib/init')
require __DIR__('model/init')
require __DIR__('api/init')

AuthSession.init()