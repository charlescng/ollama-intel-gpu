# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:noble-1.0.2
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=america/los_angeles

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Base packages
RUN apt update && \
    apt upgrade -y && \
    apt install --no-install-recommends -q -y \
    software-properties-common \
    ca-certificates \
    wget \
    ocl-icd-libopencl1

# ipex-llm suggested setup. PPA doesn't look very up-to-date
#RUN add-apt-repository -y ppa:kobuk-team/intel-graphics && \
#    apt-get install -y libze-intel-gpu1 libze1 intel-ocloc intel-opencl-icd clinfo intel-gsc intel-media-va-driver-non-free \
#    libmfx1 libmfx-gen1 libvpl2 libvpl-tools libva-glx2 va-driver-all vainfo

# Intel GPU compute user-space drivers
RUN mkdir -p /tmp/gpu && \
cd /tmp/gpu && \
wget https://github.com/oneapi-src/level-zero/releases/download/v1.26.3/level-zero_1.26.3+u24.04_amd64.deb && \
wget https://github.com/intel/intel-graphics-compiler/releases/download/v2.24.8/intel-igc-core-2_2.24.8+20344_amd64.deb && \
wget https://github.com/intel/intel-graphics-compiler/releases/download/v2.24.8/intel-igc-opencl-2_2.24.8+20344_amd64.deb && \
wget https://github.com/intel/compute-runtime/releases/download/25.48.36300.8/intel-ocloc_25.48.36300.8-0_amd64.deb && \
wget https://github.com/intel/compute-runtime/releases/download/25.48.36300.8/intel-opencl-icd_25.48.36300.8-0_amd64.deb && \
wget https://github.com/intel/compute-runtime/releases/download/25.48.36300.8/libigdgmm12_22.8.2_amd64.deb && \
wget https://github.com/intel/compute-runtime/releases/download/25.48.36300.8/libze-intel-gpu1_25.48.36300.8-0_amd64.deb && \
dpkg -i --force-all *.deb && \
rm *.deb

# Install Ollama Portable Zip
ARG IPEXLLM_RELEASE_REPO=ipex-llm/ipex-llm
ARG IPEXLLM_RELEASE_VERSON=v2.3.0-nightly
ARG IPEXLLM_PORTABLE_ZIP_FILENAME=ollama-ipex-llm-2.3.0b20250725-ubuntu.tgz
RUN cd / && \
  wget https://github.com/${IPEXLLM_RELEASE_REPO}/releases/download/${IPEXLLM_RELEASE_VERSON}/${IPEXLLM_PORTABLE_ZIP_FILENAME} && \
  tar xvf ${IPEXLLM_PORTABLE_ZIP_FILENAME} --strip-components=1 -C / && \
  rm ${IPEXLLM_PORTABLE_ZIP_FILENAME}

# OLLAMA_HOST is hardcoded to the local interface which stops other containers from connecting
RUN sed -i "s/export OLLAMA_HOST='127.0.0.1:11434'/export OLLAMA_HOST='0.0.0.0:11434'/" start-ollama.sh
# Works around an intermittent model loading failure with the Arc B580
RUN sed -i "s/export OLLAMA_KEEP_ALIVE=10m/export OLLAMA_KEEP_ALIVE=-1/" start-ollama.sh

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/bin/bash", "/start-ollama.sh"]
