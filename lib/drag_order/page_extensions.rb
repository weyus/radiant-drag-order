module DragOrder::PageExtensions
  def self.included(base)
    base.class_eval do
      self.reflections[:children].options[:order] = "position ASC"
      
      before_validation_on_create :set_initial_position
    end
    
    if defined?(Page::NONDRAFT_FIELDS)
      Page::NONDRAFT_FIELDS << 'position'
    end
  end
  
  def following_siblings
    self.class.find_all_by_parent_id(parent_id, :conditions => [ 'position > ?', position ] )
  end

private
  def set_initial_position
    self.position ||= begin
      if last_sibling = Page.find_by_parent_id(parent_id, :order => [ "position DESC" ])
        last_sibling.position + 1
      else
        0
      end
    end
  end
end
