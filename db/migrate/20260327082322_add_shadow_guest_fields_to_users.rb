class AddShadowGuestFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :guest, :boolean, default: false
    add_column :users, :ip_address, :string
    add_column :users, :fingerprint, :string

    add_index :users, :guest
    add_index :users, :fingerprint
    add_index :users, [:ip_address, :created_at]
  end
end
