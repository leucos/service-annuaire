
class PagedQuery
  attr_reader :page, :per_page

  # query = prenom =  &  nom = & page = & limit =  & order = 
  # limit=100& order=prenom & prenom=titi & etab=15
  # where
  # for the moment search would be only on columns.

  def initialize(model, columns, where, displaystart = 0, displaylength = 10, sortcol, sortdir, searchcol, searchphrase)
     
    # columns = hash key value   
    @per_page = displaylength.to_i > 0 ? displaylength.to_i : 10
    @page = displaystart.to_i/@per_page+1
    @sortcolumn = sortcol.to_i % 3
    @sortdirction = (sortdir == "desc" ? "desc" : "asc")
    @search = searchphrase
     
    begin   
	  @model= Kernel.const_get(model.downcase.capitalize)
	  raise "model n'exist pas" unless Kernel.const_get(model.downcase.capitalize)< Sequel::Model
	rescue
	  raise "model n'est pas valid "
	end 
	
	
    if columns.kind_of?(Array)
      @columns = columns
    else
      raise "le columns n'est pas une array"
    end
      @where = where
  end

    def as_json()
      {
        TotalModelRecords: @model.count,
        TotalQueryResults: records.pagination_record_count,
        Data: data
      }
    end

  private
    def data
      records.map do |r|
           a = []
           @columns.each do |c|
             if r.respond_to?(c)
               a.push(r.send(c))
             else
               a.push('empty')
             end
           end
           a
      end
    end

    def records
      fetch_records
    end

    def fetch_records
      records = @model.filter(@where)
      Ramaze::Log.debug(records)

      if sort_direction == 'asc'
        records = records.order(sort_column)
      else
        records = records.order(sort_column).reverse
      end


      if !@search.empty?
        #"nom LIKE '#{@search}%' or prenom Like '#{@search}%'"
        records = records.where("nom LIKE '#{@search}%'")
        Ramaze::Log::debug("search object #{records.count}")
      end
      records = records.paginate(page,per_page)
      records
    end

    def sort_column
      Ramaze::Log.info("Using #{@columns[@sortcolumn]} as sort key")
      @columns[@sortcolumn]
    end

    def sort_direction
      return @sortdirction
    end
end

