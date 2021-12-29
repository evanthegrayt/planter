class CommentsSeeder < Planter::Seeder
  seeding_method :csv, parent: :user, csv_name: :all_comments
end
