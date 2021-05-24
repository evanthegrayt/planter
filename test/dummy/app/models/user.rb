class User < ApplicationRecord
  has_many :addresses
  has_many :comments
  has_one :bio, class_name: 'Profile'
  has_and_belongs_to_many :roles
end
