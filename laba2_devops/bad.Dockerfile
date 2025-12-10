FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y libaa-bin
RUN apt-get install -y curl wget vim

CMD ["/usr/bin/aafire"]