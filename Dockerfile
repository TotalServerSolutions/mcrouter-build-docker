FROM ubuntu:12.04
MAINTAINER Brian Morton "bmorton@yammer-inc.com"

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get -y update && apt-get -y install curl sudo wget

ENV FOLLY_VERSION master
ENV MCROUTER_VERSION 0.9.0
ENV MCROUTER_SHA e1d90728efc109f1c7258d36b641264a56bd04a8

WORKDIR /tmp
RUN curl -L https://github.com/facebook/folly/archive/${FOLLY_VERSION}.tar.gz | tar xvz
RUN curl -L https://github.com/facebook/mcrouter/archive/v${MCROUTER_VERSION}.tar.gz | tar xvz

WORKDIR /tmp/folly-${FOLLY_VERSION}/folly
RUN apt-get -y update && ./build/deps_ubuntu_12.04.sh
RUN apt-get -y install libboost-program-options1.54-dev
RUN autoreconf -ivf && ./configure
RUN make -j4
RUN make install

WORKDIR /tmp/mcrouter-${MCROUTER_VERSION}/mcrouter
ENV LDFLAGS -Wl,-rpath=/usr/local/lib/mcrouter/
ENV LD_LIBRARY_PATH /usr/local/lib/mcrouter/
RUN mkdir /tmp/mcrouter-build && ./scripts/install_ubuntu_12.04.sh /tmp/mcrouter-build -j4

RUN add-apt-repository ppa:brightbox/ruby-ng-experimental
RUN apt-get -y update && apt-get -y install ruby2.1 ruby2.1-dev
RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc
RUN gem install fpm

WORKDIR /tmp/mcrouter-build/install
ADD /create_package.sh /tmp/mcrouter-build/install/create_package.sh
ADD /copy_deps.sh /tmp/mcrouter-build/install/copy_deps.sh
RUN ./create_package.sh ${MCROUTER_VERSION}-${MCROUTER_SHA}
