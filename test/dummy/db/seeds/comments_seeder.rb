class CommentsSeeder < Planter::Seeder
  seeding_method :csv, parent_model: 'User', csv_name: :all_comments
end
