require_relative '../helper'

describe PagedQuery do

	should "return correct data with simple columns search" do 
		#where = {:sexe=>'F', :profil_user => ProfilUser.filter(:etablissement_id => 2)}
		where = {:sexe => "F"}
    query = PagedQuery.new('User',["nom", "prenom", "id", "id_sconet"],where, 0, 10, 1, 'desc', 'sexe','')
    response = query.as_json
    response[:TotalModelRecords].should == 201
    response[:TotalQueryResults] == 105 
	end

	should "return one page(10 records) records if query returns more than one page" do 
		where = {:sexe => "F"}
    query = PagedQuery.new('User',["nom", "prenom", "id", "id_sconet"], where, 0, 10, 1, 'desc', 'sexe','')
    response = query.as_json
    response[:TotalModelRecords].should == 201
    response[:TotalQueryResults] == 105
    puts response[:Data].count
    response[:Data].count.should.be == 10 
	end

	should "return sorted results" do 
	end 

	should "Data contains only 4 columns" do 
		where = {:sexe => "F"}
    query = PagedQuery.new('User',["nom", "prenom", "id", "id_sconet"], where, 0, 10, 1, 'desc', 'sexe','')
    response = query.as_json
    response[:Data].first.count.should == 4
	end 

	should "raise error if model does not exist" do 
		where = {:sexe => "F"}
    lambda {PagedQuery.new('user',["nom", "prenom", "id", "id_sconet"], where, 0, 10, 1, 'desc', 'sexe','')}.should.not.raise(RuntimeError)
    lambda {PagedQuery.new('USER',["nom", "prenom", "id", "id_sconet"], where, 0, 10, 1, 'desc', 'sexe','')}.should.not.raise(RuntimeError)
    lambda {PagedQuery.new('USer',["nom", "prenom", "id", "id_sconet"], where, 0, 10, 1, 'desc', 'sexe','')}.should.not.raise(RuntimeError)
    lambda {PagedQuery.new('buSER',["nom", "prenom", "id", "id_sconet"], where, 0, 10, 1, 'desc', 'sexe','')}.should.raise(RuntimeError)
	end

	should "be able to filter by associated models columns" do 
		where = {:sexe=>'F', :profil_user => ProfilUser.filter(:etablissement_id => 2)}
		query = PagedQuery.new('User',["nom", "prenom", "id", "id_sconet"],where, 0, 10, 1, 'desc', 'sexe','')
    response = query.as_json
    response[:TotalModelRecords].should == 201
    response[:TotalQueryResults] == 57 
	end 

end