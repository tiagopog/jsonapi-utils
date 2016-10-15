FROM ruby:2.3.1
MAINTAINER tiagopog@gmail.com

RUN mkdir -p /jsonapi-utils
WORKDIR /jsonapi-utils

COPY . ./

RUN gem install bundler
RUN bundle install --jobs 2 --retry 10

ENTRYPOINT []
