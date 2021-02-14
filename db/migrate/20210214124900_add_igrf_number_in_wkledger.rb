class AddIgrfNumberInWkledger < ActiveRecord::Migration[5.2]
  
  def change
    add_column :wk_ledgers, :igrf_account_number, :integer
    add_column :wk_ledgers, :igrf_account_description, :string
  end
end
