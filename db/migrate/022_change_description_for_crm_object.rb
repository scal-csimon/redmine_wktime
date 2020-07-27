class ChangeDescriptionForCrmObject < ActiveRecord::Migration[5.2]
  def up

    change_table :wk_crm_activities do |t|
      t.change :description, :text, limit: 1000
    end

    change_table :wk_accounts do |t|
      t.change :description, :text, limit: 1000
    end

    change_table :wk_crm_contacts  do |t|
      t.change :description, :text, limit: 1000
    end


  end
  def down
    change_table :wk_crm_activities do |t|
      t.change :description, :string
    end

    change_table :wk_accounts do |t|
      t.change :description, :string
    end

    change_table :wk_crm_contacts  do |t|
      t.change :description, :string
    end

  end
end
