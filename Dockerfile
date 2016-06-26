FROM debian:jessie
MAINTAINER Bert Massop <bert.massop@gmail.com>

ENV USER_ID 1000
ENV GROUP_ID 1000

RUN addgroup --system --gid $GROUP_ID wine && adduser --system --uid=$USER_ID --gid=$GROUP_ID --home /wine --shell /bin/sh --gecos "Wine" wine

RUN dpkg --add-architecture i386 &&\
    apt-get update &&\
    apt-get install --no-install-recommends -y \
        ca-certificates \
        wget \
        wine32=1.6.* \
        xauth \
        xvfb \
        &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*

WORKDIR /wine
USER wine

ENV WINEPREFIX /wine/.wine32
RUN wine32 wineboot -i

ENV WINEDLLOVERRIDES "mscoree,mshtml="
RUN wget http://files.jrsoftware.org/is/5/innosetup-5.5.9-unicode.exe &&\
    echo "5b51ae6977bebba937ac18e0e80c1899e37dfaa12f51ccd817978ef07ae19cb3  innosetup-5.5.9-unicode.exe" | sha256sum --check --strict &&\
    xvfb-run wine32 innosetup-5.5.9-unicode.exe /VERYSILENT /SP- /SUPPRESSMSGBOXES /DIR="C:/Program Files/InnoSetup" &&\
    rm innosetup-5.5.9-unicode.exe

ADD build.sh ./

CMD ["./build.sh"]
