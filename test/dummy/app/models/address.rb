class Address < ApplicationRecord
  belongs_to :person, class_name: 'User', foreign_key: :user_id
end
