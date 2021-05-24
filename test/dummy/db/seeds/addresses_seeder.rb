class AddressesSeeder < Planter::Seeder
  seeding_method :data_array,
    parent_model: 'User',
    number_of_records: 2,
    unique_columns: %i[city state]

  def data
    [{
      street_1: "#{rand(100..1000)} W 8 Mile Rd",
      city: 'Detroit',
      state: 'MI',
      zip: 48219
    }]
  end
end
