require 'carrierwave'
class ImageUploader < CarrierWave::Uploader::Base
	storage :file
	#after :cache, :remove!
  #before :store, :remove!
  after :remove, :delete_empty_upstream_dirs

  def unlink_original(file)
    return unless delete_original_file
    file.delete if version_name.blank?
  end

  def store_dir
    "api/#{mounted_as}/#{model.class.to_s.underscore}/#{dyn_dir(model.id_ent)}"
  end

  def filename
    "#{secure_token(16)}_#{model.id_ent}.#{file.extension}" if original_filename 
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def delete_empty_upstream_dirs
    path = ::File.expand_path(store_dir, root)
    Dir.delete(path) # fails if path not empty dir
  rescue SystemCallError
    true # nothing, the dir is not empty
  end

  protected
  def secure_token(length=16)
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.hex(length/2))
  end
  
  def dyn_dir(id_ent)
  	regex = /([A-Z])([A-Z])([A-Z])(\d+)/
  	match =  id_ent.match(regex)
  	# if string is matched
  	if match[0]==id_ent
  		path = "#{match[1]}/#{match[2]}/#{match[3]}"
  	else
  		path =""
  	end
  	path
  end

end