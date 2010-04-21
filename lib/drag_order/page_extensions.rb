module DragOrder::PageExtensions
  def self.included(base)
    base.class_eval do
      self.reflections[:children].options[:order] = "position ASC"
      
      before_validation_on_create :set_initial_position
      validates_numericality_of :position, :greater_than_or_equal_to => 0, :only_integer => true
      validates_uniqueness_of :position, :scope => :parent_id
    end
    
    if defined?(Page::NONDRAFT_FIELDS)
      Page::NONDRAFT_FIELDS << 'position'
    end
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
