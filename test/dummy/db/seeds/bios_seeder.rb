class BiosSeeder < Planter::Seeder
  seeding_method :data_array,
    model: 'Profile',
    parent: :user

  def data
    [{ bio: "I'm a test." }]
  end
end
