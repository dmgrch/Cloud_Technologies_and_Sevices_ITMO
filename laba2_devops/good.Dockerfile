FROM ubuntu:22.04

RUN apt-get update && apt-get install -y libaa-bin

CMD ["/usr/bin/aafire"]