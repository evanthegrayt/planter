ARG RUBY_VERSION=3.2

FROM ruby:${RUBY_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends \
  libsqlite3-dev \
  sqlite3 \
  vim \
  && rm -rf /var/lib/apt/lists/*

ENV APP_HOME=/srv/app \
  BUNDLE_GEMFILE=/srv/app/Gemfile \
  BUNDLE_PATH=/bundle \
  BUNDLE_BIN=/bundle/bin \
  BUNDLE_JOBS=8 \
  BUNDLE_RETRY=3

ENV PATH="${BUNDLE_BIN}:${APP_HOME}/test/dummy/bin:${PATH}"

WORKDIR $APP_HOME

RUN gem install bundler

COPY . $APP_HOME/

RUN bundle check || bundle install

ENTRYPOINT ["bash", "/srv/app/docker/entrypoint"]
CMD ["bash"]
