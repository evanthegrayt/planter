class CreateRoles < ActiveRecord::Migration[6.1]
  def change
    create_table :roles do |t|
      t.text :name
      t.timestamps
    end
  end
end
