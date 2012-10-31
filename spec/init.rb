require 'simplecov'

# Load the existing files
Dir["spec/**/*.rb"].each do |spec_file|
  if File.basename(spec_file) != 'init.rb' and File.basename(spec_file) != 'helper.rb'
    next if File.dirname(spec_file).include?("fixtures")
    next if File.dirname(spec_file).include?("api")
    # Exclude integration tests by default
    if File.dirname(spec_file).include?('integration') and !ENV["EXTENDED_SPECS"]
      puts "% Skipping spec file : #{spec_file} (define EXTENDED_SPECS to run integration tests)"
      next
    end
    if File.dirname(spec_file).include?('alimentation') and !File.dirname(spec_file).include?('utest')
      puts "On ne fait pas les tests d'integration de l'alimentation #{spec_file}"
      next
    end
    puts "% Using spec file : #{spec_file}"
    require File.expand_path(spec_file)
  end
end