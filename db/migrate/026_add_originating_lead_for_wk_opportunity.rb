class AddOriginatingLeadForWkOpportunity < ActiveRecord::Migration[5.2]
  
  def up
    add_reference :wk_opportunities, :originating_lead, :class => "wk_lead", :null => true, index: true

  end
  
  def down
    remove_reference :wk_opportunities, :originating_lead, :class => "wk_lead", :null => true, index: true

  end
end
