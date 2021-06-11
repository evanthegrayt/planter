class UsersSeeder < Planter::Seeder
  seeding_method :csv, unique_columns: :email
end
