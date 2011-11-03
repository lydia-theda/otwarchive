class TagSweeper < ActionController::Caching::Sweeper
  observe Tag
  
  def after_create(tag)
    if tag.canonical
      tag.add_to_autocomplete
    end
    update_tag_nominations(tag)
  end
  
  def after_update(tag)
    if tag.canonical_changed?
      if tag.canonical
        # newly canonical tag
        tag.add_to_autocomplete
      else
        tag.remove_from_autocomplete
      end
    end
    update_tag_nominations(tag)
  end

  def before_destroy(tag)
    if Tag::USER_DEFINED.include?(tag.type) && tag.canonical
      tag.remove_from_autocomplete
    end
    update_tag_nominations(tag, deleted=true)
  end
  
  private

  def update_tag_nominations(tag, deleted=false)
    values = {}
    if deleted
      values[:canonical] = false
      values[:exists] = false
      values[:parented] = false
      values[:synonym] = nil
    else
      values[:canonical] = tag.canonical
      values[:synonym] = tag.merger.nil? ? nil : tag.merger.name
      values[:parented] = tag.parents.any? {|p| p.is_a?(Fandom)}
      values[:exists] = true    
    end
    TagNomination.where(:tagname => tag.name).update_all(values)
  end
    

end