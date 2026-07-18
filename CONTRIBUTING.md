# Contributing

Thanks for helping improve Planter. This project is a Rails engine gem with a
dummy Rails app under `test/dummy` for exercising the gem in a real Rails
environment.

## Setup

Use Ruby 3.2 or newer. The supported Ruby floor is defined in
`planter.gemspec`, and CI currently runs the suite against Ruby 3.2, 3.3, and
4.0.

Install dependencies from the repository root.

```bash
bundle install
```

The lockfile records the Bundler version used by the project. If `bundle
install` asks for a different Bundler version, install the version shown under
`BUNDLED WITH` in `Gemfile.lock`.

The dummy app uses SQLite. The test helper maintains the test schema when the
test suite starts, so normal test runs do not require a separate database setup
step.

## Running Tests

Run the full test suite with either command.

```bash
bundle exec rake
bin/test
```

Run a single test file with `bin/test`.

```bash
bin/test test/planter/seeder_test.rb
```

The default rake task is `test`, and GitHub Actions runs `bundle exec rake`.

## Formatting

This project uses Standard Ruby. Check formatting and style with:

```bash
bundle exec rake standard
```

## Documentation

When code or public API documentation changes, regenerate the docs before
opening a pull request.

```bash
bundle exec rake rerdoc
```

## Dummy App

The Rails app in `test/dummy` is the local host application used by the engine
tests. It is useful when you need to run Rails commands against a real app, for
example:

```bash
cd test/dummy
bin/rails db:migrate
bin/rails planter:seed
```

Most contributors should not need to run the dummy app as a web server. It is
primarily a fixture and command target for development and tests.

## Docker

Docker is optional. The `Dockerfile` and `docker-compose.yml` build a local Ruby
environment and install the gem dependencies. They are useful if you want an
isolated development shell or need to exercise the dummy app without relying on
your host Ruby setup.

Build the image and open a shell from the repository root.

```bash
docker compose build app
docker compose run --rm app bash
```

The container installs gems into `/bundle`, which is mounted as a named Docker
volume. That volume survives `docker compose down`, so installed gems do not
need to be reinstalled each time. The volume is removed by `docker compose down
-v` or `docker system prune --volumes`; if that happens, the entrypoint runs
`bundle check || bundle install` on the next container start.

The Compose build uses Ruby 3.2 by default because that is the gem's supported
Ruby floor. To try another supported Ruby version, pass `RUBY_VERSION`.

```bash
RUBY_VERSION=4.0 docker compose build app
```

Prepare the dummy database and run Planter inside the container.

```bash
cd test/dummy
bin/rails db:prepare
SEEDERS=users,addresses,bios,roles,comments bin/rails planter:seed
```

Docker is not part of the current test command or CI workflow. The GitHub
Actions workflow uses `ruby/setup-ruby`, installs dependencies with Bundler, and
runs `bundle exec rake` directly on the runner.

## Pull Requests

Before opening a pull request, please run:

```bash
bundle exec rake
bundle exec rake standard
bundle exec rake rerdoc
```

For behavior changes, add or update tests under `test/`. For documentation
changes, keep examples aligned with the public API shown in `README.md`.
