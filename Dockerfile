# Use phusion/passenger-full as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/passenger-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/passenger-customizable:1.0.11

# Set correct environment variables.
ENV HOME /root
USER root

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# If you're using the 'customizable' variant, you need to explicitly opt-in
# for features.
#
# N.B. these images are based on https://github.com/phusion/baseimage-docker,
# so anything it provides is also automatically on board in the images below
# (e.g. older versions of Ruby, Node, Python).
#
# Uncomment the features you want:
#
#   Ruby support
#RUN /pd_build/ruby-2.3.*.sh
#RUN /pd_build/ruby-2.4.*.sh
#RUN /pd_build/ruby-2.5.*.sh
#RUN /pd_build/ruby-2.6.*.sh
RUN /pd_build/ruby-2.7.*.sh
#RUN /pd_build/jruby-9.2.*.sh
#   Python support.
#RUN /pd_build/python.sh
#   Node.js and Meteor standalone support.
#   (not needed if you already have the above Ruby support)
#RUN /pd_build/nodejs.sh


# Update bundler
RUN gem install bundler

# Install imagemagick + dependencies
RUN apt-get update && apt-get install -y -qq --no-install-recommends apt-utils sudo tzdata wget \
	imagemagick ghostscript build-essential unzip net-tools bc curl ssmtp debconf
RUN apt-get install libaio1
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install nginx-headers-more package
RUN apt-get update && apt-get install -y -qq --no-install-recommends libnginx-mod-http-headers-more-filter
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# add yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN echo "deb [trusted=yes] https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install yarn

# Set timezone correctly
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime && printf 'America\nNew_York\n' | dpkg-reconfigure tzdata

# Create temporary SSL certificate for local development
RUN mkdir -p /etc/pki/tls
RUN mkdir -p /etc/pki/tls/certs
RUN mkdir -p /etc/pki/tls/private
RUN echo "copy_extensions = copy\n" >> /etc/ssl/openssl.cnf
RUN echo "subjectAltName=email:copy\n" >> /etc/ssl/openssl.cnf
RUN echo "issuerAltName=issuer:copy\n" >> /etc/ssl/openssl.cnf

RUN openssl req -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=US/ST=Massachusetts/L=Cambridge/O=Broad Institute/OU=BITS DevOps/CN=localhost/subjectAltName=localhost/emailAddress=dmeyer@broadinstitute.org" \
    -keyout /etc/pki/tls/private/localhost.key \
    -out /etc/pki/tls/certs/localhost.crt

# Add Root CA and DHE key-exchange cert
COPY ./GeoTrust_Universal_CA.pem /usr/local/share/ca-certificates
COPY ./dhparam.pem /usr/local/share/ca-certificates
