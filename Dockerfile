# Stage 1: Building
FROM alpine:3.10.2 AS build
# Build tools
RUN apk add --no-cache git g++ make cmake
# Build SEAL & spsl
RUN mkdir /building && cd /building && \
    git clone https://github.com/microsoft/SEAL.git && cd SEAL/native/src && \
    cmake . && make -j8 && cd /building && \
    git clone https://github.com/secure-pprl/secure-p-signature-linkage.git && \
    cd secure-p-signature-linkage/ && \
    CPPFLAGS='-isystem /building/SEAL/native/src' LIBSEAL_PATH=/building/SEAL/native/lib/libseal.a make -j8

# Stage 2: Deployment
FROM centos:7 AS deploy
# Library packages required for running
RUN yum install centos-release-scl epel-release -y && \
    yum install rh-python36 libstdc++ libgomp -y
RUN ln -sr /opt/rh/rh-python36/root/usr/bin/python3 /usr/bin/python3
RUN python3 -m pip install cffi numpy
# Brings over essential SEAL source and SPPRL systems
COPY --from=build /building/SEAL/native/src/seal /building/SEAL/native/src/seal
COPY --from=build /building/secure-p-signature-linkage /building/secure-p-signature-linkage
# Move items into place
RUN cd /building/secure-p-signature-linkage && \
    cp secure-linkage /usr/local/bin && cp libseclink.so /usr/local/lib && \
    cp seclink.py /opt

RUN ln -sr /usr/local/lib/libseclink.so /opt/rh/rh-python36/root/usr/local/lib/libseclink.so && \
    ln -sr /usr/local/bin/secure-linkage /opt/rh/rh-python36/root/usr/local/bin/secure-linkage && \
    ln -sr /opt/seclink.py /opt/rh/rh-python36/root/opt/seclink.py

# Sets Non-Root user for running instances after image setup
RUN groupadd spprlgroup && adduser pprluser -G spprlgroup
USER pprluser

# Final touches
WORKDIR /opt
CMD ["python3", "-ic", "import seclink;  seclink.run_test(log=print)"]
