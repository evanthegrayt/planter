require 'planter'

Planter.configure do |c|
  c.seeders = %i[users addresses bios roles comments]
end
