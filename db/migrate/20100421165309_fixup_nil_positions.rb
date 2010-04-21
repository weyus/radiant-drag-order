class FixupNilPositions < ActiveRecord::Migration
  def self.up
    say_with_time('Fixing position values on all pages…') do
      without_timestamping do
        homepage = Page.find_by_parent_id(nil)
        fix_child_positions(homepage)
      end
    end
  end
  
  def self.fix_child_positions(parent)
    parent.children.each_with_index do |page, index|
      page.update_attribute :position, index + 1
      fix_child_positions page
    end
  end
  
  def self.without_timestamping
    ActiveRecord::Base.record_timestamps = false
    yield if block_given?
    ActiveRecord::Base.record_timestamps = true
  end

  def self.down
  end
  
end
