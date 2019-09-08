FROM ubuntu:xenial
RUN apt -y update
RUN apt -y install openssl ca-certificates iptables conntrack
RUN apt -y install sed grep coreutils python-pip
RUN pip install awscli
RUN apt -y install vim
COPY scripts/* /usr/bin/

