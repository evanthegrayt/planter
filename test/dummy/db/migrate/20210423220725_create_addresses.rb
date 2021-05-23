class CreateAddresses < ActiveRecord::Migration[6.1]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :street_1
      t.string :street_2
      t.string :city
      t.string :state, limit: 2
      t.string :zip
      t.timestamps
    end
  end
end
