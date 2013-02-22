require 'mongo'
require 'bson'

module DataBase
  class << self
    
    #connect to mongodb
    def connect(config)
      @db = Mongo::Connection.new(config[:server],config[:port] || 27017).db(config[:db])
    end
    
    # mongo collections 
    #[:etablissement, :user, :regroupement, :profil_user, :telephone, :email, :relation_eleve, :membre_regroupement, :enseigne_regroupement] 
    # we must also add indexes in oorder to accelerate the search 
    
    
    def find(search)
      if search == :all
        #return all
        yasi = @db.collection("yasis").find.to_a
        return nil_or_array(yasi)
      else
        return find_with_criteria(search)
      end
    end

    def save(yasi)
      stringify_keys(yasi)
      # handle author first
      if yasi["author"]
        stringify_keys(yasi["author"])
        author = @db.collection("authors").find_one(yasi["author"])
        # if the author does not exist, then create one 
        unless author
          author = @db.collection("authors").save(yasi["author"])
        end
        yasi["author"] = author
      end

      # save with the yasi with the author
      # once again, please validate before save
      # this is for educational purpose only.
      @db.collection("yasis").save(yasi)
    end

    def delete(id)
      victim = @db.collection("yasis").find_one(BSON::ObjectId.from_string(id))
      @db.collection("yasis").remove(victim) if victim
    end

    private

    def find_with_criteria(search)
      stringify_keys(search)
      if search["author"]
        author = @db.collection("authors").find_one stringify_keys(search["author"])
        if author
          search[:author] = author
          yasi = @db.collection("yasis").find(search).to_a
          return nil_or_array yasi
        else
          return nil
        end
      else
        yasi = @db.collection("yasis").find(search).to_a
        return nil_or_array(yasi)
      end
    end

    def stringify_keys(hash)
      h = {}
      hash.each do |key, value|
        h[key.to_s] = value
      end
      h
    end

    def nil_or_array(result)
      if result.size == 0
        return nil
      else
        return result
      end
    end

  end
end