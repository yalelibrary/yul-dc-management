FROM yalelibraryit/dc-base:v1.4.7
ENV NODE_OPTIONS="--openssl-legacy-provider"

COPY ops/webapp.conf /etc/nginx/sites-enabled/webapp.conf
COPY ops/env.conf /etc/nginx/main.d/env.conf
# Asset compile and migrate if prod, otherwise just start nginx
COPY ops/nginx.sh /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run
RUN rm -f /etc/service/nginx/down
# these are used for image and pdf processing, and may not be required for an image not running delayed jobs
RUN apt-get update --allow-releaseinfo-change && apt-get install -y wget libtiff-tools liblcms2-dev libexif-dev libmagickcore-dev imagemagick libexpat-dev libtiff5-dev libgsf-1-dev libjpeg-turbo8-dev vim openjdk-11-jre-headless \
  &&  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ops/policy.xml /etc/ImageMagick-6/policy.xml
COPY ops/policy.xml /etc/ImageMagick-7/policy.xml

# Compile and install vips 8.10.6
# TODO building new packages is broken in this version of 20.04, once an update is released
# the faster pre built package version can be brought back
COPY --chown=app ops/vips $APP_HOME/ops/vips
RUN bash -l -c " \
  wget https://github.com/libvips/libvips/releases/download/v8.10.6/vips-8.10.6.tar.gz && \
  tar zxfv vips-8.10.6.tar.gz && \
  cd vips-8.10.6 && \
  ./configure && \
  make && \
  make install && \
  ldconfig"
# COPY vips_8.10.2-1_amd64.deb $APP_HOME
# RUN dpkg -i ./vips_8.10.2-1_amd64.deb
# RUN vips --version

COPY jpegs2pdf-1.3.jar $APP_HOME

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
BUNDLE_JOBS=4
RUN /sbin/setuser app bash -l -c "gem install bundler -v 2.3.8"

COPY --chown=app Gemfile* $APP_HOME/
RUN /sbin/setuser app bash -l -c "bundle check || bundle install"

COPY  --chown=app . $APP_HOME

RUN groupadd -g 12005 nfs_share && usermod -aG nfs_share app
RUN groupadd -g 117 goobi && usermod -aG goobi app
# Assets and packs are moved aside - building them means you find out early if the asset compilation is broken
# not on final deploy. It means that public/assets and public/packs can be volumes in production allowing for
# cached pages / assets to be kept and cleaned the way Rails expects them to be while keeping deployment very fast.
# The assets/packs get copied back by rsync on app load (see ops/nginx.sh)
RUN /sbin/setuser app bash -l -c " \
    SECRET_KEY_BASE=thisisfakesoassetscompile RAILS_ENV=production RAILS_RELATIVE_URL_ROOT=/management DB_ADAPTER=nulldb yarn install && bundle exec rake assets:precompile && \
    mv ./public/assets ./public/assets-new && \
    mv ./public/packs ./public/packs-new"

EXPOSE 3001
