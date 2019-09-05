# Stage 1: Building
FROM fedora:30 AS build
# Build tools
RUN dnf install gcc g++ make cmake git -y
# Build SEAL & spsl
RUN mkdir /building && cd /building && \
    git clone https://github.com/microsoft/SEAL.git && cd SEAL/native/src && \
    cmake . && make -j 2 && cd /building && \
    git clone https://github.com/secure-pprl/secure-p-signature-linkage.git && \
    cd secure-p-signature-linkage/ && \
    CPPFLAGS='-isystem /building/SEAL/native/src' LIBSEAL_PATH=/building/SEAL/native/lib/libseal.a make -j 2

# Stage 2: Deploy
FROM fedora:30 AS deploy
# Build tools
RUN dnf install libstdc++ libgomp python3-numpy python3-cffi -y
# Build SEAL & spsl
COPY --from=build /building/SEAL/native/src/seal /building/SEAL/native/src/seal
COPY --from=build /building/secure-p-signature-linkage /building/secure-p-signature-linkage

RUN cd /building/secure-p-signature-linkage && \
    cp secure-linkage /usr/local/bin && cp libseclink.so /opt && \
    cp seclink.py /opt

# Sets Non-Root user for running instances after image setup
RUN groupadd spprlgroup && adduser pprluser -G spprlgroup
USER pprluser

RUN cd /opt && ls

# Final touches
WORKDIR /opt
CMD ["python3", "-ic", "import seclink;  seclink.run_test(log=print)"]


# Stage 2: Deployment
#FROM centos:7 AS deploy
# Library packages required for running
#RUN yum install centos-release-scl epel-release -y && \
#    yum install rh-python36 libstdc++ libgomp -y
#RUN ln -sr /opt/rh/rh-python36/root/usr/bin/python3 /usr/bin/python3
#RUN python3 -m pip install cffi numpy
# Brings over essential SEAL source and SPPRL systems
#COPY --from=build /building/SEAL/native/src/seal /building/SEAL/native/src/seal
#COPY --from=build /building/secure-p-signature-linkage /building/secure-p-signature-linkage
# Move items into place
#RUN cd /building/secure-p-signature-linkage && \
#    cp secure-linkage /usr/local/bin && cp libseclink.so /usr/local/lib && \
#    cp seclink.py /opt

#RUN ln -sr /usr/local/lib/libseclink.so /opt/rh/rh-python36/root/usr/local/lib/libseclink.so && \
#    ln -sr /usr/local/bin/secure-linkage /opt/rh/rh-python36/root/usr/local/bin/secure-linkage && \
#    ln -sr /opt/seclink.py /opt/rh/rh-python36/root/opt/seclink.py

# Sets Non-Root user for running instances after image setup
#RUN groupadd spprlgroup && adduser pprluser -G spprlgroup
#USER pprluser

# Final touches
#WORKDIR /opt
#CMD ["python3", "-ic", "import seclink;  seclink.run_test(log=print)"]
