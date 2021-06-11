class BiosSeeder < Planter::Seeder
  seeding_method :data_array,
    model: 'Profile',
    parent_model: 'User',
    association: :bio

  def data
    [{ bio: "I'm a test." }]
  end
end
