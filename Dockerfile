FROM ruby:3.3.5-bookworm AS ccs-base

RUN apt-get update -y && \
    apt-get upgrade -y

ENV WORKDIR=/code
WORKDIR $WORKDIR
RUN useradd -m apps && \
    mkdir -p /home/apps && chown apps:apps /home/apps && \
    chmod 777 /tmp

FROM ccs-base AS ccs-app-base
RUN echo 123

FROM ccs-app-base AS ccs-app-code
COPY Gemfile ./
COPY Gemfile.lock ./

RUN bundle install

COPY /src/app.rb ./
ENV PATH=$WORKDIR/bin:$PATH
RUN chown -R apps:apps $WORKDIR && \
    chmod 777 $WORKDIR
USER apps
ENTRYPOINT [ "ruby", "./app.rb" ]