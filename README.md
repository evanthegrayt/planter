# Planter
[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fevanthegrayt%2Fplanter%2Fbadge%3Fref%3Dmaster&style=flat)](https://actions-badge.atrox.dev/evanthegrayt/planter/goto?ref=master)
[![Language: Ruby](https://img.shields.io/static/v1?label=language&message=Ruby&color=CC342D&style=flat&logo=ruby&logoColor=CC342D)](https://www.ruby-lang.org/)
[![Gem Version](https://img.shields.io/gem/v/planter.svg)](https://rubygems.org/gems/planter)
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
Add the following line to your application's Gemfile.

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

To get started, run `rails generate planter:initializer`, which will create
`config/initializers/planter.rb` with the following contents.

```ruby
require 'planter'
require 'planter/adapters/active_record'

Planter.configure do |config|
  ##
  # The adapter used to create records, discover parent records, and
  # inspect database table names. Active Record is used by default.
  # To use a custom adapter, replace this line with your own adapter.
  config.adapter = Planter::Adapters::ActiveRecord.new

  ##
  # The list of seeders. These files are stored in the
  # config.seeders_directory, which can be changed below. When a new
  # seeder is generated, it will be appended to the bottom of this
  # list. If the order is incorrect, you'll need to adjust it.
  # The generator can append to either multiline or inline %i[...]
  # arrays.
  config.seeders = %i[
  ]

  ##
  # The directory where the seeders are kept.
  config.seeders_directory = 'db/seeds'

  ##
  # The directory where CSVs are kept.
  config.csv_files_directory = 'db/seed_files'

  ##
  # When true, don't print output when seeding.
  config.quiet = false

  ##
  # The default trim mode for ERB. Valid modes are:
  # '%'  enables Ruby code processing for lines beginning with %
  # '<>' omit newline for lines starting with <% and ending in %>
  # '>'  omit newline for lines ending in %>
  # '-'  omit blank lines ending in -%>
  # I recommend reading the help documentation for ERB::new()
  config.erb_trim_mode = nil
end
```

By default, a `planter:seed` task is provided for seeding your application. This
allows you to use `db:seed` for other purposes. If you want Planter to hook
into the existing `db:seed` task, simply add the following to `db/seeds.rb`.

```ruby
# db/seeds.rb
Planter.seed
```

Before seeding, you can validate your Planter configuration without creating
records.

```bash
rails planter:validate
```

This command loads the Rails environment, checks the configured seeders, and
verifies that the configured adapter exposes Planter's adapter API. It prints a
success message when no issues are found, warnings for non-fatal issues, and
errors before exiting non-zero when the seed plan is not valid.

Like `planter:seed`, validation supports the `SEEDERS` environment variable if
you want to check only part of the configured plan.

```bash
rails planter:validate SEEDERS=users,addresses
```

To create a users seeder, run `rails generate planter:seeder users`. Usually,
seeders seed a specific table, so it's recommended to name your seeders after
the table. If you don't, specify the table with the `table` option in
`seeding_method`. This will create a file named `db/seeds/users_seeder.rb` (the
directory will be created if it doesn't exist) with the following contents.

```ruby
class UsersSeeder < Planter::Seeder
  # TODO: Choose a seeding_method. For example:
  # seeding_method :csv

  # For now, we override the seed method so no exception will be raised.
  def seed
  end
end
```

This also adds `users` to the `config.seeders` array in our initializer. A few
things to note.

- The seeder will always be appended at the end of the array. If this is not the
correct order, you'll need to adjust the array manually.
- The generator can append to either multiline or inline `%i[...]` seeders
arrays.

You can also tell the generator which seeding style to use.

```bash
rails generate planter:seeder users --seeding-method=csv
rails generate planter:seeder users --seeding-method=data-array
rails generate planter:seeder users --seeding-method=custom
```

`--seeding-method=csv` creates a seeder with `seeding_method :csv` and creates
`db/seed_files/users.csv` with headers pulled from the `users` table.
`--seeding-method=data-array` creates a seeder with `seeding_method :data_array`
and an empty `data` method. `--seeding-method=custom` creates a seeder with an
empty `seed` method, which is useful when the built-in seeding methods don't
fit.

If you want to generate a seeder for every table currently in your database, run
`rails generate planter:seeder ALL`. The seeding style options can be used with
`ALL`, too; for example,
`rails generate planter:seeder ALL --seeding-method=csv`.

Planter uses `Planter::Adapters::ActiveRecord` by default, so the built-in
seeding methods work with Active Record models without extra configuration. See
[Custom Adapters](#custom-adapters) if you want to use a different persistence
backend.

Each generated seeder needs a seeding method. In practice:

- Use `csv` when the seed data should live in a file that is easy to review or
  edit outside Ruby.
- Use `data_array` when the seed data should be generated dynamically in Ruby.
- Use a custom `seed` method when the built-in persistence flow is not the right
  fit for the job.

### Seeding from CSV
To seed from CSV, you simply need to add the following to your seeder class.

```ruby
class UsersSeeder < Planter::Seeder
  seeding_method :csv
end
```

Then, create a directory called `db/seed_files`, and create a CSV file called
`db/seed_files/users.csv`. You can also run
`rails generate planter:seeder users --seeding-method=csv` to create this file
automatically. In this file, the headers should be the field names, and the rest
of the rows should be the corresponding data.

```
email,username
test1@example.com,test1
test2@example.com,test2
```

For idempotent seeds, pass `unique_columns` to control which columns are used to
find existing records. This example finds users by email and only uses
`username` when creating a new record.

```ruby
class UsersSeeder < Planter::Seeder
  seeding_method :csv, unique_columns: :email
end
```

```
email,username
test1@example.com,test1
test2@example.com,test2
```

CSV seeders can also be useful for simple model-less tables, such as join
tables. With the default Active Record adapter, Planter will use the model when
one exists and fall back to direct table inserts when one does not.

```ruby
class RolesUsersSeeder < Planter::Seeder
  seeding_method :csv
end
```

```
user_id,role_id
1,1
2,1
```

If the CSV file is named differently than the seeder, you can specify the
`:csv_name` option. Note that the value should not include the file extension.
If the seeder name does not match the table being seeded, specify the `:table`
option.

```ruby
class UsersSeeder < Planter::Seeder
  seeding_method :csv, csv_name: :people
end

class PeopleSeeder < Planter::Seeder
  seeding_method :csv, table: :users
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
usually the place where they're needed most, but they work with any method.

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

You can also seed child records for every existing record of a parent relation.
For example, to seed an address for every user, you'd need to create an
`AddressesSeeder` that uses the `parent` option, as seen below. This option
is interpreted by the configured adapter. With the default Active Record adapter,
it should be the name of the `belongs_to` association on a model-backed table.
The primary key, foreign key, and persistence details will all be determined by
the adapter.

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
records *for each record of the parent relation*.

### Custom seeds
To write your own custom seeds, generate with `--seeding-method=custom` or
override the `seed` method and do whatever you need to do. This is the right
choice when the seed depends on application-specific service objects, multiple
tables, or logic that does not map cleanly to CSV or `data_array`.

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

## Custom Adapters
Active Record is the default adapter, but you can provide your own adapter
object in the initializer. Replace the generated Active Record adapter require
and configuration with your custom adapter, while keeping `config.seeders` as
your ordered seed plan. The default adapter creates records through Active
Record models when they exist, and falls back to direct table inserts for
model-less tables such as join tables.

For a full tutorial, see the
[Writing a Custom Adapter](https://github.com/evanthegrayt/planter/wiki/Writing-a-Custom-Adapter)
wiki page.

You can generate a custom adapter stub with the following command.

```bash
$ rails generate planter:adapter sequel
```

This creates `lib/planter/adapters/sequel.rb` with the required adapter methods,
updates `config/initializers/planter.rb`, and leaves `config.seeders` unchanged.

```ruby
require 'planter'
require 'my_adapter'

Planter.configure do |config|
  config.adapter = MyAdapter.new
end
```

Custom adapters are duck typed. They do not need to expose model objects; at
minimum, they should implement the same table-oriented public API as
`Planter::Adapters::ActiveRecord`.

```ruby
class MyAdapter
  def create_record(context:, lookup_attributes:, create_attributes:)
    # Find or create a record for context.table_name.
  end

  def parent_ids(context:)
    # Return ids for each parent record used by parent seeding.
  end

  def foreign_key(context:)
    # Return the attribute used to attach a parent id to the seeded record.
  end

  def table_columns(context:)
    # Return native columns or fields for context.table_name.
  end

  def table_names
    # Return table or collection names used by `rails generate planter:seeder ALL`.
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

## Support this project
I love knowing when people find my work useful. Any kind of support is very much
appreciated!

- ⭐️ Like the project? Star [the repository](https://github.com/evanthegrayt/planter)!
- ❤️ Love the project? Follow me [on GitHub](https://github.com/evanthegrayt)!
- 💸 *Really* love it? Consider [buying me a tea](https://paypal.me/evanrgray)!
