# Generated by Neurodocker version 0.5.0
# Timestamp: 2020-09-16 16:07:32 UTC
# 
# Thank you for using Neurodocker. If you discover any issues
# or ways to improve this software, please submit an issue or
# pull request on our GitHub repository:
# 
#     https://github.com/kaczmarj/neurodocker

FROM neurodebian:stretch-non-free

ARG DEBIAN_FRONTEND="noninteractive"

ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN export ND_ENTRYPOINT="/neurodocker/startup.sh" \
    && apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           apt-utils \
           bzip2 \
           ca-certificates \
           curl \
           locales \
           unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG="en_US.UTF-8" \
    && chmod 777 /opt && chmod a+s /opt \
    && mkdir -p /neurodocker \
    && if [ ! -f "$ND_ENTRYPOINT" ]; then \
         echo '#!/usr/bin/env bash' >> "$ND_ENTRYPOINT" \
    &&   echo 'set -e' >> "$ND_ENTRYPOINT" \
    &&   echo 'export USER="${USER:=`whoami`}"' >> "$ND_ENTRYPOINT" \
    &&   echo 'if [ -n "$1" ]; then "$@"; else /usr/bin/env bash; fi' >> "$ND_ENTRYPOINT"; \
    fi \
    && chmod -R 777 /neurodocker && chmod a+s /neurodocker

ENTRYPOINT ["/neurodocker/startup.sh"]

RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           fsl-core \
           git \
           num-utils \
           gcc \
           g++ \
           curl \
           build-essential \
           nano \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN bash -c 'curl -sL https://deb.nodesource.com/setup_10.x | bash - && apt-get install -y nodejs && apt-get install -y npm'

RUN sed -i '$isource /etc/fsl/fsl.sh' $ND_ENTRYPOINT

ENV CONDA_DIR="/opt/miniconda-latest" \
    PATH="/opt/miniconda-latest/bin:$PATH"
RUN export PATH="/opt/miniconda-latest/bin:$PATH" \
    && echo "Downloading Miniconda installer ..." \
    && conda_installer="/tmp/miniconda.sh" \
    && curl -fsSL --retry 5 -o "$conda_installer" https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash "$conda_installer" -b -p /opt/miniconda-latest \
    && rm -f "$conda_installer" \
    && conda update -yq -nbase conda \
    && conda config --system --prepend channels conda-forge \
    && conda config --system --set auto_update_conda false \
    && conda config --system --set show_channel_urls true \
    && sync && conda clean --all && sync \
    && conda create -y -q --name bidsonym \
    && conda install -y -q --name bidsonym \
           'python=3.6' \
           'numpy' \
           'nipype' \
           'nibabel' \
           'pandas' \
    && sync && conda clean --all && sync \
    && bash -c "source activate bidsonym \
    &&   pip install --no-cache-dir  \
             'deepdefacer' \
             'tensorflow' \
             'scikit-image'" \
    && rm -rf ~/.cache/pip/* \
    && sync \
    && sed -i '$isource activate bidsonym' $ND_ENTRYPOINT

RUN bash -c 'source activate bidsonym && git clone https://github.com/poldracklab/pydeface.git && cd pydeface && python setup.py install && cd -'

RUN bash -c 'source activate bidsonym && git clone https://github.com/nipy/quickshear.git  && cd quickshear && python setup.py install && cd -'

RUN bash -c 'source activate bidsonym && git clone https://github.com/neuronets/nobrainer.git  && cd nobrainer && python setup.py install && cd -'

RUN bash -c 'mkdir -p /opt/nobrainer/models && cd /opt/nobrainer/models && curl -LJO  https://github.com/neuronets/nobrainer-models/releases/download/0.1/brain-extraction-unet-128iso-model.h5 && cd ~ '

RUN bash -c 'git clone https://github.com/mih/mridefacer'

ENV MRIDEFACER_DATA_DIR="/mridefacer/data"

RUN bash -c 'npm install -g bids-validator@1.5.4'

RUN bash -c 'mkdir /home/mri-deface-detector && cd /home/mri-deface-detector && npm install sharp --unsafe-perm && npm install -g mri-deface-detector --unsafe-perm && cd ~'

RUN bash -c 'git clone https://github.com/miykael/gif_your_nifti && cd gif_your_nifti && source activate bidsonym && python setup.py install'

COPY [".", "/home/bm"]

RUN bash -c 'chmod a+x /home/bm/bidsonym/fs_data/mri_deface'

RUN bash -c 'source activate bidsonym && cd /home/bm && pip install -e .'

ENV IS_DOCKER="1"

WORKDIR /tmp/

ENTRYPOINT ["/neurodocker/startup.sh", "bidsonym"]