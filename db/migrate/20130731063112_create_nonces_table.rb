class CreateNoncesTable < ActiveRecord::Migration
  def change
    create_table :nonces do |t|
      t.string :nonce, :null => false, :default => ""
      t.integer :request_time, :null => false, :default => 0
    end

    add_index :nonces, :nonce
    add_index :nonces, :request_time
  end
end
