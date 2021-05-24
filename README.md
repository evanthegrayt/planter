# Planter
[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fevanthegrayt%2Fplanter%2Fbadge%3Fref%3Dmaster&style=flat)](https://actions-badge.atrox.dev/evanthegrayt/planter/goto?ref=master)
[![Gem Version](https://badge.fury.io/rb/planter.svg)](https://badge.fury.io/rb/planter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> Pre-release version! Anything is subject to change in the near future!

Seeds for Rails applications can get complicated fast, and Rails doesn't provide
much for assisting with this process. This plugin seeks to rectify that by
providing easy ways to seed specific tables by hooking into the existing `rails
db:seed` task.

Features include:

- Seed tables from CSV files, an array of hashes, or custom methods.
- Call specific seeders with `rails db:seed SEEDERS=users,addresses`.
- Control the number of records being created.
- Seed associations.

You can view the documentation [here](https://evanthegrayt.github.io/planter/).

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'planter'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install planter
```

## Usage
Let's assume you'd like to seed your `users` table.

To get started, simply add the following to your `db/seeds.rb` file. Note that
the `config.seeders` should be an array of the seeders to use. They should be in
the correct order to successfully seed the tables when considering associations.

```ruby
require 'planter'

Planter.configure do |config|
  config.seeders = %i[ users ]
end

Planter.seed
```

Then, create a directory called `db/seeds`, and create a file called
`db/seeds/users_seeder.rb`. In that file, create the following class. Note the
name of the seeder is the name of the table, plus `Seeder`, and it inherits from
`Planter::Seeder`.

```ruby
class UsersSeeder < Planter::Seeder
end
```

You then need to choose a seeding method, of which there are currently three.

### Seeding from CSV
To seed from CSV, you simply need to add the following to your seeder class.

```ruby
class UsersSeeder < Planter::Seeder
  seeding_method :csv
end
```

Then, create a directory called `db/seed_files`, and create a csv file called
`db/seed_files/users.csv`. In this file, the header should be the field names,
and the rest of the rows should be the corresponding data.

```
email,username
test1@example.com,test1
test2@example.com,test2
```

If the CSV file is named differently than the seeder, you can specify the
`:csv_name` option. Note that the value should not include the file extension.

```ruby
class UsersSeeder < Planter::Seeder
  seeding_method :csv, csv_name: :people
end
```

`ERB` can be used in the CSV files if you name it with `.erb` at the end of the
file name. For example, `users.csv.erb`. Note that lines starting with `<%` and
ending with `%>` will not be considered rows, so you can use `ERB` rows to set
values. For example:

```csv.erb
email,login_attempts
<% count = 1 %>
test2@example.com,<%= count += 1 %>
test2@example.com,<%= count += 1 %>
```

Running `rails db:seed` will now seed your `users` table.

## Seeding from a data array
If you need dynamic seeds, you can add something similar to the following to
your seeder class. In this example, we'll use
[faker](https://github.com/faker-ruby/faker).

```ruby
require 'faker' # You should really just require this in `db/seeds.rb`.

class UsersSeeder < Planter::Seeder
  seeding_method :data_array, number_of_records: 10

  def data
    [{
      email: Faker::Internet.email,
      username: Faker::Name.name
    }]
  end
end
```

The `number_of_records` option allows you to only create one array element, but
create ten records. If you leave this option off, you'll need your array to have
ten elements to create ten records. It's also worth noting that setting an
instance variable called `@data` from an `initialize` method would also work, as
the `Planter::Seeder` parent class automatically provides `attr_reader :data`.

Running `rails db:seed` should now seed your `users` table.

You can also seed children records for every existing record of a parent model.
For example, to seed an address for every user, you'd need to create an
`AddressesSeeder` that uses the `parent_model` option, as seen below.

```ruby
require 'faker'

class AddressesSeeder < Planter::Seeder
  seeding_method :data_array, parent_model: 'User'

  def data
    [{
      street: Faker::Address.street_address,
      city: Faker::Address.city,
      state: Faker::Address.state_abbr,
      zip: Faker::Address.zip
    }]
  end
end
```

Note that specifying `number_of_records` in this instance will create that many
records *for each record of the parent model*. You can also specify the
association if it's different from the table name, using the `:assocation`
option.

### Custom seeds
To write your own custom seeds, just overload the `seed` method and do whatever
you need to do.

```ruby
class UsersSeeder < Planter::Seeder
  USERS = {
    'test1@example.com' => { username: 'John Smith' },
    'test2@example.com' => { username: 'Jane Smith' }
  }

  def seed
    USERS.each { |email, attrs| User.where(email).first_or_create!(attrs) }
  end
end
```

## Customization
You can change the directories of both the seeder files and the CSV files. In
your `configure` block in `db/seeds.rb`, you can add the following. Note that,
in both instances, the path should be relative to `Rails.root`.

```ruby
require 'planter'

Planter.configure do |config|
  config.seeders_directory = 'db/seeder_classes'
  config.csv_files_directory = 'db/csvs'
  config.seeders = %i[
    users
    addresses
  ]
end

Planter.seed
```

## License
The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Reporting Bugs and Requesting Features
If you have an idea or find a bug, please [create an
issue](https://github.com/evanthegrayt/planter/issues/new). Just make sure
the topic doesn't already exist. Better yet, you can always submit a Pull
Request.

## Self-Promotion
I do these projects for fun, and I enjoy knowing that they're helpful to people.
Consider starring [the repository](https://github.com/evanthegrayt/planter)
if you like it! If you love it, follow me [on
Github](https://github.com/evanthegrayt)!
