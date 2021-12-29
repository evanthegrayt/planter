class CommentsSeeder < Planter::Seeder
  seeding_method :csv, parent: :user, csv_name: :all_comments

  def transformations
    { message: ->(v) { v.sub(/test/, 'TEST') } }
  end
end
