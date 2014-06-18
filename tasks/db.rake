# coding: utf-8

namespace :db do
  APP_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  desc 'Loading database server configuration and sequel extensions.'
  task :load_config do
    require 'sequel'
    require './config/database'
    Sequel.extension :migration
    Sequel.extension :schema_dumper
  end

  desc 'Configuring database server.'
  task :configure do
    require 'erb'
    File.open(File.join( APP_ROOT, 'config', 'database.rb'), 'w') do |new_file|
      new_file.write ERB.new(File.read(File.join(APP_ROOT, 'config', 'database.erb'))).result(binding)
    end
  end

  desc 'Dumps the schema to db/schema/sequel_schema.db'
  task schemadump: :load_config do
    # foreign_key dump is sometimes wrong with non autoincrmente type (ie char)
    # so we need to dump the base in two times : the structure without foreign_keys and the foreigne_key alone
    schema = DB.dump_schema_migration(foreign_key: false)
    File.open(File.join(APP_ROOT, 'migrations', '001_db_schema.rb'), 'w'){|f| f.write(schema)}
    fk = "\n# Adding Foreign Keys \n\n" << DB.dump_foreign_key_migration
    File.open(File.join(APP_ROOT, 'migrations', '001_db_schema.rb'), 'a'){|f| f.write(fk)}
  end

  desc 'Apply migrations'
  task migrations: :load_config do
    Sequel::Migrator.run( DB, 'migrations' )
  end

  desc 'Open pry with DB environment setup'
  task pry: :load_config do
    require 'pry'
    require './models/models'
    pry.binding
  end

  namespace :migrate do
    desc  'Rollbacks the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x. Target specific version with VERSION=x.'
    task :redo => :load_config do
      Rake::Task["db:rollback"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:schemadump"].invoke
    end

    desc 'Runs the "up" for a given migration VERSION.'
    task :up => :load_config do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      puts "migrating up to version #{version}"
      Sequel::Migrator.apply(DB, File.join(RAMAZE_ROOT, 'db', 'migrations'), version)
      Rake::Task["db:schemadump"].invoke
    end

    desc 'Runs the "down" for a given migration VERSION.'
    task :down => :load_config do
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      current_version = Sequel::Migrator.get_current_migration_version(DB)
      down_version = current_version - step
      down_version = 0 if down_version < 0
      puts "migrating down to version #{down_version}"
      Sequel::Migrator.apply(DB, File.join(RAMAZE_ROOT, 'db', 'migrations'), down_version)
      Rake::Task["db:schemadump"].invoke
    end
  end

  desc 'Rolls the schema back to the previous version. Specify the number of steps with STEP=n'
  task :rollback => :load_config do
    Rake::Task["db:migrate:down"].invoke
  end

  desc 'Truncate all tables and insert intial laclasse.com data (profil, matiere etc.)'
  task :bootstrap => :load_config do
    require_relative '../db/scripts/bootstrap'
    bootstrap_annuaire()
  end

  desc 'Truncate famille_matiere and matiere_enseignee and fill them with BCN data'
  task :bootstrap_matiere => :load_config do
    require_relative '../db/scripts/bcn_parser'
    bootstrap_matiere()
  end

  desc 'Truncate all user table but let laclasse.com datas (good for test)'
  task :clean => :load_config do
    require_relative '../db/scripts/bootstrap'
    clean_annuaire()
  end
  #task :reset => ['db:schema:drop', 'db:schema:load']

end
