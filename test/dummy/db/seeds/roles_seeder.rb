class RolesSeeder < Planter::Seeder
  ROLE_NAMES = %w[admin user]

  def seed
    ROLE_NAMES.each { |role| Role.where(name: role).first_or_create! }
    User.all.each { |user| user.roles << Role.find_by(name: ROLE_NAMES.sample) }
  end
end
