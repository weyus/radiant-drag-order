class FixupNilPositions < ActiveRecord::Migration
  def self.up
    say_with_time('Fixing position values on all pages…') do
      ActiveRecord::Base.record_timestamps = false
      Page.all.each do |page|
        unless page.parent #homepage
          page.update_attribute :position, 0
        else
          # set pages to the position that they appear in the admin interface
          new_position = page.parent.children.index(page)
          page.update_attribute :position, new_position
        end
      end
      ActiveRecord::Base.record_timestamps = true
    end
  end

  def self.down
  end
  
end
