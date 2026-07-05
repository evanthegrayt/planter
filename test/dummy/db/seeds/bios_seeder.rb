class BiosSeeder < Planter::Seeder
  seeding_method :data_array,
    table: :profiles,
    parent: :user

  def data
    [{bio: "I'm a test."}]
  end
end
