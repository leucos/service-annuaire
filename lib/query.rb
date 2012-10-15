
class PagedQuery
  attr_reader :page, :per_page

  # query = prenom =  &  nom = & page = & limit =  & order = 
  # limit=100& order=prenom & prenom=titi & etab=15
  # where
  # for the moment search would be only on columns.

  def initialize(model, columns, where, displaystart = 0, displaylength = 10, sortcol, sortdir, searchphrase)
     
    # columns = hash key value   
    @per_page = displaylength.to_i > 0 ? displaylength.to_i : 10
    @page = displaystart.to_i/@per_page+1
    @sortcolumn = sortcol.to_i
    @sortdirction = (sortdir == "desc" ? "desc" : "asc")
    @search = searchphrase.split(" ")
     
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
           a = {}
           a[:json_class] = @model.to_s
           @columns.each do |c|
             if r.respond_to?(c)
               a[c] =  r.send(c)
             end
           end
           a
      end
    end

=begin
    def data
      rec = records 
      first_round = true 
      @columns.each do |col|
        if (first_round)
          rec = rec.select(col)
          first_round = false
        else 
          rec  = rec.select_append(col)
        end
      end
      rec
    end 
=end
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
        condition = ''
        first_round = true 
        @search.each do |token|
          if (first_round)
            condition = condition + "nom sounds like '%#{token}%' or prenom sounds like '%#{token}%'"
            first_round = false
          else
            condition = condition + "or nom sounds like '%#{token}%' or prenom sounds like '%#{token}%'"
          end
        end
        records = records.where(condition)
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

    def columns_stringify
      return @columns.map{|v| v.is_a?(String) ? v: v.to_s}
    end 
end

