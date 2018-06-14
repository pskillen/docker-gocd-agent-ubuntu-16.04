# Copyright 2017 ThoughtWorks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM ubuntu:18.04
MAINTAINER GoCD <go-cd-dev@googlegroups.com>

LABEL gocd.version="18.6.0" \
  description="GoCD agent based on ubuntu version 18.04" \
  maintainer="Patrick Skillen <pskillen@gmail.com>" \
  gocd.full.version="18.6.0-6883" \
  gocd.git.sha="1013a67ccf0cda9c87e6361286708b584be42338"

ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini-static-amd64 /usr/local/sbin/tini
ADD https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64 /usr/local/sbin/gosu


# force encoding
ENV LANG=en_US.utf8

ARG UID=1000
ARG GID=1000

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
  chmod 0755 /usr/local/sbin/gosu && \
  chown root:root /usr/local/sbin/gosu && \
# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
  groupadd -g ${GID} go && \
  useradd -u ${UID} -g go -d /home/go -m go && \
  apt-get update && \
  apt-get install -y openjdk-11-jre-headless git subversion mercurial openssh-client bash unzip curl && \
  apt-get autoclean && \
# download the zip file
  curl --fail --location --silent --show-error "https://download.gocd.org/binaries/18.6.0-6883/generic/go-agent-18.6.0-6883.zip" > /tmp/go-agent.zip && \
# unzip the zip file into /go-agent, after stripping the first path prefix
  unzip /tmp/go-agent.zip -d / && \
  mv go-agent-18.6.0 /go-agent && \
  rm /tmp/go-agent.zip && \
  mkdir -p /docker-entrypoint.d

# ensure that logs are printed to console output
COPY agent-bootstrapper-logback-include.xml /go-agent/config/agent-bootstrapper-logback-include.xml
COPY agent-launcher-logback-include.xml /go-agent/config/agent-launcher-logback-include.xml
COPY agent-logback-include.xml /go-agent/config/agent-logback-include.xml

ADD docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
