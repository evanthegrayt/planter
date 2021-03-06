# Planter
[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fevanthegrayt%2Fplanter%2Fbadge%3Fref%3Dmaster&style=flat)](https://actions-badge.atrox.dev/evanthegrayt/planter/goto?ref=master)
[![Gem Version](https://badge.fury.io/rb/planter.svg)](https://badge.fury.io/rb/planter)
![Language: Ruby](https://img.shields.io/static/v1?label=language&message=Ruby&color=CC342D&style=flat&logo=ruby&logoColor=CC342D)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Seeds for Rails applications can get complicated fast, and Rails doesn't provide
much for assisting with this process. This plugin seeks to rectify that by
providing easy ways to seed specific tables.

Features include:

- Seed tables from CSV files, an array of hashes, or custom methods.
- Call specific seeders with `rails planter:seed SEEDERS=users,addresses`.
- Control the number of records being created.
- Seed associations.

You can view the documentation [here](https://evanthegrayt.github.io/planter/).

## Installation
Add the following line to your application's Gemfile. Because this plugin is
currently a pre-release version, it's recommended to lock it to a specific
version, as breaking changes may occur, even at the minor level.

```ruby
gem 'planter', '0.2.0'
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

To get started, run `rails generate planter:initializer`, which will create
`config/initializers/planter.rb` with the following contents.

```ruby
require 'planter'

Planter.configure do |config|
  ##
  # The list of seeders. These files are stored in the
  # config.seeders_directory, which can be changed below. When a new
  # seeder is generated, it will be appended to the bottom of this
  # list. If the order is incorrect, you'll need to adjust it.
  # Just be sure to keep the ending bracket on its own line, or the
  # generator won't know where to put new elements.
  config.seeders = %i[
  ]

  ##
  # The directory where the seeders are kept.
  # config.seeders_directory = 'db/seeds'

  ##
  # The directory where CSVs are kept.
  # config.csv_files_directory = 'db/seed_files'

  ##
  # The default trim mode for ERB. Valid modes are:
  # '%'  enables Ruby code processing for lines beginning with %
  # '<>' omit newline for lines starting with <% and ending in %>
  # '>'  omit newline for lines ending in %>
  # '-'  omit blank lines ending in -%>
  # I recommend reading the help documentation for ERB::new()
  # config.erb_trim_mode = nil
end
```

By default, a `planter:seed` task is provided for seeding your application. This
allows you to use `db:seed` for other purposes. If you want Planter to hook
into the existing `db:seed` task, simply add the following to `db/seeds.rb`.

```ruby
# db/seeds.rb
Planter.seed
```

To create a users seeder, run `rails generate planter:seeder users`. Usually,
seeders seed a specific table, so it's recommended to name your seeders after
the table. If you don't, you'll need to manually specify a few things. More on
that later. This will create a file named `db/seeds/users_seeder.rb` (the
directory will be created if it doesn't exist) with the following contents.

```ruby
class UsersSeeder < Planter::Seeder
  # TODO: Choose a seeding_method. For example:
  # seeding_method :csv

  # For now, we overload the seed method so no exception will be raised.
  def seed
  end
end
```

This also adds `users` to the `config.seeders` array in our initializer. A few
things to note.

- The seeder will always be appended at the end of the array. If this is not the
correct order, you'll need to adjust the array manually.
- When adjusting the array, always keep the closing bracket on its own line, or
the generator won't know where to put the new seeders.

If you want to generate a seeder for every table currently in your database, run
`rails generate planter:seeder ALL`.

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

`ERB` can be used in the CSV files if you end the file name with `.csv.erb` or
`.erb.csv`. For example, `users.csv.erb`. When using ERB, instance variables set
in the seeder can be used in the CSV.

```ruby
class UsersSeeder < Planter::Seeder
  seeding_method :csv, csv_name: :people

  def initialize
    @name_prefix = 'Test User'
  end
end
```

```
participant_id,name
<%= Participant.find_by(email: 'test1@example.com').id %>,<%= @name_prefix %> 1
<%= Participant.find_by(email: 'test2@example.com').id %>,<%= @name_prefix %> 2
```

Note that, if you need to change the trim mode for ERB, you can set a default in
the initializer.

```ruby
Planter.configure do |config|
  config.seeders = %i[
    users
  ]
  config.erb_trim_mode = '<>'
end
```

...or, for individual seeders, via `seeding_method`.

```ruby
class UsersSeeder < Planter::Seeder
  seeding_method :csv, erb_trim_mode: '<>'
end
```

For help with `erb_trim_mode`, see the help documentation for `ERB::new`.

Lastly, it's worth mentioning `transformations` under the CSV section, as that's
usually the pace where they're needed most, but it will work with any method.

If you're seeding with a CSV, and it contains values that need to have code
executed on them before it's imported into the database, you can define an
instance variable called `@transformations`, or a method called
`transformations`, that returns a Hash of field names, and Procs to run on the
value. For example, if you have an `admin` column, and the CSV contains "true",
it will come through as a String, but you probably want it to be a Boolean. This
can be solved with the following.

```ruby
class UsersSeeder < Planter::Seeder
  seeding_method :csv

  def transformations
    {
      admin: ->(value) { value == 'true' },
      last_name: ->(value, row) { "#{value} #{row[:suffix]}".squish }
    }
  end
end
```

When defining a Proc/Lambda, you can make it accept 0, 1, or 2 arguments.
- When `0`, the value is replaced by the result of the Lambda
- When `1`, the value is passed to the Lambda, and is subsequently replaced by
  the result of the Lambda
- When `2`, the value is the first argument, and the entire row, as a Hash, is
  the second argument. This allows for more complicated transformations that can
  be dependent on other fields and values in the record.

Running `rails planter:seed` will now seed your `users` table.

## Seeding from a data array
If you need dynamic seeds, you can add something similar to the following to
your seeder class. In this example, we'll use
[faker](https://github.com/faker-ruby/faker).

```ruby
require 'faker' # You could just require this in `db/seeds.rb`.

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

Running `rails planter:seed` should now seed your `users` table.

You can also seed children records for every existing record of a parent model.
For example, to seed an address for every user, you'd need to create an
`AddressesSeeder` that uses the `parent` option, as seen below. This option
should be the name of the `belongs_to` association in your model. The primary
key, foreign key, and model name of the parent will all be determined by
reflecting on the association.

```ruby
require 'faker'

class AddressesSeeder < Planter::Seeder
  seeding_method :data_array, parent: :user

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
records *for each record of the parent model*.

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
    USERS.each { |email, attrs| User.where(email: email).first_or_create!(attrs) }
  end
end
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
GitHub](https://github.com/evanthegrayt)!
