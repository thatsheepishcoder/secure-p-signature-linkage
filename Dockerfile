# FULL CENTOS BUILD

# Stage1: Build
FROM centos:7 AS build
# Library packages required for running
RUN yum install epel-release centos-release-scl -y && \
    yum install libstdc++ libgomp devtoolset-8-gcc devtoolset-8-gcc-c++ cmake3 git make -y
RUN scl enable devtoolset-8 -- bash
RUN bash
RUN mkdir /building && cd /building && \
    git clone https://github.com/microsoft/SEAL.git && cd SEAL/native/src && \
    CXX=/opt/rh/devtoolset-8/root/usr/bin/c++ CC=/opt/rh/devtoolset-8/root/usr/bin/gcc cmake3 . && \
    CXX=/opt/rh/devtoolset-8/root/usr/bin/g++ CC=/opt/rh/devtoolset-8/root/usr/bin/gcc make -j 2 && \
    cd /building && git clone https://github.com/secure-pprl/secure-p-signature-linkage.git && \
    cd secure-p-signature-linkage/ && \
    CXX=/opt/rh/devtoolset-8/root/usr/bin/g++ CC=/opt/rh/devtoolset-8/root/usr/bin/gcc CPPFLAGS='-isystem /building/SEAL/native/src' LIBSEAL_PATH=/building/SEAL/native/lib/libseal.a make -j 2

# Stage2: Deploy
FROM centos:7 AS deploy
# Library packages required for running
RUN yum install epel-release -y && \
    yum install python36 libstdc++ libgomp -y
RUN python3 -m ensurepip && python3 -m pip install cffi numpy
COPY --from=build /building/SEAL/native/src/seal /building/SEAL/native/src/seal
COPY --from=build /building/secure-p-signature-linkage /building/secure-p-signature-linkage
# Move items into place
RUN cd /building/secure-p-signature-linkage && \
    cp secure-linkage /usr/local/bin && cp libseclink.so /lib64 && \
    cp seclink.py /opt

# Sets Non-Root user for running instances after image setup
RUN groupadd spprlgroup && adduser pprluser -G spprlgroup
USER pprluser

# Final touches
WORKDIR /opt
CMD ["python3", "-ic", "import seclink;  seclink.run_test(log=print)"]



###########
### Fedora-like build
# Stage 1: Building
#FROM fedora:30 AS build
# Build tools, fastest mirror helps
#RUN echo "fastestmirror=true" >> /etc/dnf/dnf.conf && \
#    dnf install gcc g++ make cmake git -y
# Build SEAL & spsl
#RUN mkdir /building && cd /building && \
#    git clone https://github.com/microsoft/SEAL.git && cd SEAL/native/src && \
#    cmake . && make -j 2 && cd /building && \
#    git clone https://github.com/secure-pprl/secure-p-signature-linkage.git && \
#    cd secure-p-signature-linkage/ && \
#    CPPFLAGS='-isystem /building/SEAL/native/src' LIBSEAL_PATH=/building/SEAL/native/lib/libseal.a make -j 2


# This was used as a tester to ensure the movement between Fedora to others
# would not break anything.
# Stage 2: Deploy
#FROM fedora:30 AS deploy
# Build tools
#RUN dnf install libstdc++ libgomp python3-numpy python3-cffi -y
# Build SEAL & spsl
#COPY --from=build /building/SEAL/native/src/seal /building/SEAL/native/src/seal
#COPY --from=build /building/secure-p-signature-linkage /building/secure-p-signature-linkage

#RUN cd /building/secure-p-signature-linkage && \
#    cp secure-linkage /usr/local/bin && cp libseclink.so /lib64 && \
#    cp seclink.py /opt

# Sets Non-Root user for running instances after image setup
#RUN groupadd spprlgroup && adduser pprluser -G spprlgroup
#USER pprluser

# Final touches
#WORKDIR /opt
#CMD ["python3", "-ic", "import seclink;  seclink.run_test(log=print)"]
