FROM ruby:3.0

RUN apt-get update && apt-get install -y \
  vim sqlite3

ENV APP_HOME /srv/app

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
    BUNDLE_JOBS=8 

ENV PATH=$APP_HOME/test/dummy/bin:$PATH

RUN gem install bundler

COPY . $APP_HOME/
RUN bundle check || bundle install

WORKDIR $APP_HOME/test/dummy
RUN rails db:create db:migrate
