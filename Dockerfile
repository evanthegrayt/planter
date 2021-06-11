FROM ruby:3.0

RUN apt-get update && apt-get install -y \
  vim sqlite3

ENV APP_HOME /srv/app

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
    BUNDLE_JOBS=8 \
    BUNDLE_PATH=/bundle_cache

WORKDIR $APP_HOME
