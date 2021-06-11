FROM ruby:3.0.1
RUN apt-get update -qq && \
    apt-get install -y build-essential sqlite3 libsqlite3-dev vim
ENV EDITOR vim
RUN mkdir /app
WORKDIR /app

RUN gem install bundler

COPY planter.gemspec /app
COPY Gemfile /app
COPY Gemfile.lock /app
COPY lib/planter/version.rb /app/lib/planter/version.rb
RUN bundle check || bundle install
COPY . /app
