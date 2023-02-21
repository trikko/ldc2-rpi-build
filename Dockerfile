FROM arm32v7/debian:bullseye-slim

ENV LDC_VERSION="1.31.0"

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -yq tzdata && \
    ln -fs /usr/share/zoneinfo/Europe/Rome /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN apt-get install -y git wget llvm cmake zlib1g-dev ldc clang

RUN wget "https://github.com/ldc-developers/ldc/releases/download/v$LDC_VERSION/ldc-$LDC_VERSION-src.tar.gz" && tar xvf ldc-$LDC_VERSION-src.tar.gz

RUN mkdir /ldc-build && cd /ldc-build && \
  cmake ../ldc-$LDC_VERSION-src \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/ldc-release && \
  cmake --build . --target install -j12

# PATCH TO FIX A BUG IN STD.PROCESS
RUN cat /ldc-$LDC_VERSION-src/runtime/phobos/std/process.d | sed 's/if (poll(pfds, maxToClose, 0) >= 0)/version (none)/g' > /tmp/process.d
RUN mv /tmp/process.d /ldc-$LDC_VERSION-src/runtime/phobos/std/process.d 

RUN mkdir /ldc-build-bootstrap && cd /ldc-build-bootstrap && \
  cmake ../ldc-$LDC_VERSION-src \
  -DCMAKE_BUILD_TYPE=Release \
  -DD_COMPILER=/ldc-build/bin/ldmd2 \
  -DLDC_INSTALL_LLVM_RUNTIME_LIBS=ON \
  -DBUILD_SHARED_LIBS=BOTH \
  -DCMAKE_INSTALL_PREFIX=/ldc-bootstrapped && \
   cmake --build . --target install -j8

RUN perl -pi -e "s?/ldc-bootstrapped/?%%ldcbinarypath%%/../?g" /ldc-bootstrapped/etc/ldc2.conf && cat /ldc-bootstrapped/etc/ldc2.conf

ENV DMD="/ldc-bootstrapped/bin/ldmd2"

RUN git clone --recursive https://github.com/dlang/tools.git dlang-tools && cd dlang-tools && git checkout `cat /ldc-$LDC_VERSION-src/packaging/dlang-tools_version`
RUN mkdir dlang-tools/bin
RUN cd dlang-tools && $DMD -w -de -dip1000 rdmd.d -of=bin/rdmd
RUN cd dlang-tools && $DMD -w -de -dip1000 ddemangle.d -of=bin/ddemangle
RUN cd dlang-tools && $DMD -w -de -dip1000 DustMite/dustmite.d DustMite/splitter.d DustMite/polyhash.d -of=bin/dustmite
RUN cp dlang-tools/bin/rdmd /ldc-bootstrapped/bin/
RUN cp dlang-tools/bin/ddemangle /ldc-bootstrapped/bin/
RUN cp dlang-tools/bin/dustmite /ldc-bootstrapped/bin/

RUN git clone --recursive https://github.com/dlang/dub.git
RUN cd dub && git checkout `cat /ldc-$LDC_VERSION-src/packaging/dub_version` && $DMD -run build.d -O -w -linkonce-templates
RUN cp dub/bin/dub ldc-bootstrapped/bin

RUN git clone --recursive https://github.com/atilaneves/reggae.git
RUN cd reggae && git checkout `cat /ldc-$LDC_VERSION-src/packaging/reggae_version`
RUN cd reggae && DFLAGS="-O -linkonce-templates" /ldc-bootstrapped/bin/dub build -v --build-mode=allAtOnce --combined
RUN cp reggae/bin/reggae /ldc-bootstrapped/bin

RUN mv /ldc-bootstrapped /ldc-$LDC_VERSION
ENTRYPOINT mkdir -p deploy && tar czf /deploy/ldc-$LDC_VERSION-arm-bullseye.tar.gz /ldc-$LDC_VERSION/*
