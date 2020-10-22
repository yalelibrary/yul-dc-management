FROM yalelibraryit/dc-base:v1.1.0

COPY ops/webapp.conf /etc/nginx/sites-enabled/webapp.conf
COPY ops/env.conf /etc/nginx/main.d/env.conf
# Asset compile and migrate if prod, otherwise just start nginx
COPY ops/nginx.sh /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run
RUN rm -f /etc/service/nginx/down
RUN apt-get update && apt-get install -y libtiff-tools liblcms2-dev libexif-dev libmagickcore-dev imagemagick libexpat-dev libtiff5-dev libgsf-1-dev libjpeg-turbo8-dev \
  &&  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ops/policy.xml /etc/ImageMagick-6/policy.xml

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
BUNDLE_JOBS=4
RUN gem install bundler -v 2.1.4

COPY libvips.8.10.precomp.tgz $APP_HOME
RUN tar -xzf $APP_HOME/libvips.8.10.precomp.tgz && cd vips-8.10.2 && make install
RUN ldconfig /usr/local/lib
RUN rm -rf  libvips.8.10.precomp.tgz  vips-8.10.2

COPY --chown=app Gemfile* $APP_HOME/
RUN /sbin/setuser app bash -l -c "bundle check || bundle install"

COPY  --chown=app . $APP_HOME

# Assets and packs are moved aside - building them means you find out early if the asset compilation is broken
# not on final deploy. It means that public/assets and public/packs can be volumes in production allowing for
# cached pages / assets to be kept and cleaned the way Rails expects them to be while keeping deployment very fast.
# The assets/packs get copied back by rsync on app load (see ops/nginx.sh)
RUN /sbin/setuser app bash -l -c " \
    SECRET_KEY_BASE=thisisfakesoassetscompile RAILS_ENV=production RAILS_RELATIVE_URL_ROOT=/management DB_ADAPTER=nulldb bundle exec rake assets:precompile && \
    mv ./public/assets ./public/assets-new && \
    mv ./public/packs ./public/packs-new"

EXPOSE 3001
