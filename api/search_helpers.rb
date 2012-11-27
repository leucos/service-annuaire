#encoding: utf-8

module SearchHelpers
  # Algo dégeux pour découper les éléments de la requète
  # qui sont séparés par des espaces, sauf quand les espaces sont entre double quote
  # Y a sûrement plus simple et plus efficace mais j'ai pas trouvé...
  def split_query(query)
    bad_split = query.split(' ')
    good_split = []
    to_combine = nil
    bad_split.each do |v|
      if v.index('"') and v.index('"') == v.rindex('"')
        # On enlève les doubles quotes
        v.tr_s!('"', '')
        if to_combine
          # Fin de chaine avec espace
          good_split.push("#{to_combine} #{v}")
          to_combine = nil
        else
          # Début de chaine avec espace
          to_combine = v
        end
      elsif to_combine
        # Milieu de chaine avec espace
        to_combine = "#{to_combine} #{v}"
      else
        v.tr_s!('"', '')
        # Chaine simple
        good_split.push(v)
      end
    end
    good_split
  end

  def apply_filter!(patterns, dataset, accepted_fields)
    # Ensuite parmis ces patterns, il y a peut-être des champs spécifique
    # qui sont définit par des ":" ex : nom:test
    # Donc on les sépare
    field_patterns = patterns.select {|p| p.split(':').length > 1}
    fuzzy_patterns = patterns - field_patterns

    # Puis on fait une requète "fuzzy" sur les champs non spécifiés
    dataset = dataset.search(accepted_fields, fuzzy_patterns)

    # Puis on filtre de manière les champs spécifiés un par un
    field_patterns.each do |fp|
      field, pattern = fp.split(':')
      field = field.to_sym
      error!("Champ de recherche #{field} non accepté", 400) unless accepted_fields.include?(field)
      dataset = dataset.filter(field => pattern)
    end

    return dataset
  end

  # Applique au dataset un tri ascendant ou descandant sur une des colonnes acceptées
  def apply_sort!(column, order, dataset, accepted_fields)
    column = column.to_sym
    error!("Colonne de tri #{column} non acceptée", 400) unless accepted_fields.include?(column)
    # Par défault, l'ordre est asc
    if order and order.downcase == "desc"
      dataset = dataset.order(Sequel.desc(column))
    else
      dataset = dataset.order(Sequel.asc(column))
    end

    return dataset
  end

  def super_search!(dataset, accepted_fields)
    if params[:query]
      patterns = split_query(params[:query])
      dataset = apply_filter!(patterns, dataset, accepted_fields)
    end

    column = params[:sort]
    order = params[:order]
    if column
      dataset = apply_sort!(column, order, dataset, accepted_fields)
    elsif order
      error!("Ordre de tri définit sans colonne (sort)", 400)
    end

    # todo : Limit arbitraire de 500, gérer la limit max en fonction du profil ?
    page_size = params[:limit] ? params[:limit] : 500
    page_no = params[:page] ? params[:page] : 1

    dataset.paginate(page_no, page_size)
  end
end