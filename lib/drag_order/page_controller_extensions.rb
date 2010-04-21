module DragOrder::PageControllerExtensions
  def move_to
    @page = Page.find(params[:id])
    @old_parent = @page.parent
    @loc = params[:pos].to_i
    
    remove_page_from_old_position unless copying?
    
    @rel = Page.find(params[:rel])
    make_room_for_page if @loc != 2
    
    if copying?
      # Save reference to parts
      @orig_parts = @page.parts
      # Create copy of page
      @page = @page.clone
    end
    
    @rel.reload
    
    put_page
    
    solve_slug_conflicts if copying? || new_parent_different?
    
    @page.save!
    
    create_copy_of_parts if copying?
    
    clear_cache
    redirect_back_to_admin_pages_page
  end
  
private
  def copying?
    params[:copy].to_i > 0
  end
  
  def remove_page_from_old_position
    @page.following_siblings.each do |sibling|
      sibling.position -= 1
      sibling.save!
    end
  end
  
  def put_page
    if @loc != 2
      @page.parent = @rel.parent
      @page.position = @rel.position.to_i + (@loc == 1 ? 1 : -1)
    else
      @page.parent = @rel
      @page.position = 1
    end
  end
  
  def make_room_for_page
    new_siblings = Page.find_all_by_parent_id(@rel.parent_id, :conditions => [ 'position >= ?', @rel.position + @loc ])
    new_siblings.each do |sibling|
      if sibling != @page || copying?
        sibling.position += 1
        sibling.save!
      end
    end
  end
  
  def new_parent_different?
    # @page.parent.changed? always gives false...
    @page.parent != @old_parent
  end
  
  def solve_slug_conflicts
    check_slug = @page.slug.sub(/-copy-?[0-9]*$/, "")
    count = 0
    duplicates = Page.find_all_by_parent_id( @loc == 2 ? @rel.id : @rel.parent.id, :conditions => [ "slug LIKE '?%%'", check_slug ] )
    duplicates.each do |d|
      m = d.slug.match("^#{check_slug}(-copy-?([0-9]*))?$")
      if !m.nil?
        if !(m[2].nil? || m[2] == "")
          nc = m[2].to_i + 1
        elsif m[1]
          nc = 2
        else
          nc = 1
        end
        count = nc if nc > count
      end
    end
    if count > 0
      # Remove old copy counters
      re = / - COPY ?[0-9]*$/
      @page.title.sub! re, ""
      @page.breadcrumb.sub! re, ""
      # Add new copy counters
      @page.slug = check_slug + "-copy" + (count > 1 ? "-" + count.to_s : "")
      @page.title += " - COPY" + (count > 1 ? " " + count.to_s : "")
      @page.breadcrumb += " - COPY" + (count > 1 ? " " + count.to_s : "")
    end
  end
  
  def create_copy_of_parts
    @orig_parts.each do |op|
      @page.parts.create({
        :name => op.name,
        :filter_id => op.filter_id,
        :content => op.content
      })
    end
  end

  def redirect_back_to_admin_pages_page
    request.env["HTTP_REFERER"] ? redirect_to(:back) : redirect_to(admin_page_url)
  end

  def clear_cache
    if defined? ResponseCache == 'constant'
      ResponseCache.instance.clear
    else
      Radiant::Cache.clear
    end
  end
end
