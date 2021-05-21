# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[6.1]
  create_table :users do |t|
    t.string :email, null: false, index: { unique: true }
    t.string :username, null: false, index: { unique: true }

    t.timestamps
  end
end
