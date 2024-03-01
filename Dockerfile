FROM nvidia/cuda:11.3.1-devel-ubuntu20.04 
# 11.3 required for openfold

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME 
    # && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    # && apt-get update \
    # && apt-get install -y sudo \
    # && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    # && chmod 0440 /etc/sudoers.d/$USERNAME
    # && rm -rf /var/lib/apt/lists/* 

# Install zsh and ohmyzsh
RUN apt-get update && apt-get install -yq zsh sudo curl wget jq vim git-core gnupg locales && apt-get clean && rm -rf /var/lib/apt/lists/*

# Default powerline10k theme, no plugins installed
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)" -- \
    -t robbyrussell
RUN sudo chsh -s /bin/zsh

# credits: @pangyuteng
# refer to: https://gist.github.com/pangyuteng/f5b00fe63ac31a27be00c56996197597
# Use the above args during building https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact

ARG MINIFORGE=Miniforge-pypy3-Linux-x86_64.sh
# Install miniconda to /miniconda
# RUN curl -LO "http://repo.continuum.io/miniconda/Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh"
# RUN curl -LO "https://repo.anaconda.com/miniconda/${MINICONDA}" && bash ${MINICONDA} -p /miniconda -b && rm ${MINICONDA}
# RUN bash Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh -p /miniconda -b
# RUN rm Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh
# ENV PATH=/miniconda/bin:${PATH}
# RUN conda update -y conda
              
RUN curl -LO "https://github.com/conda-forge/miniforge/releases/latest/download/${MINIFORGE}" && bash ${MINIFORGE} -p /mambaforge -b && rm ${MINIFORGE}
ENV PATH=/mambaforge/bin:${PATH}
# RUN mamba update -y mamba

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN mamba clean -a -y && pip cache purge

# ********************************************************
# * Anything else you want to do like clean up goes here *
# ********************************************************

# [Optional] Set the default user. Omit if you want to keep the default as root.
# USER $USERNAME

# install oh-my-zsh for vscode
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)" -- \
    -t robbyrussell

# ------------------- install OpenFold and ESM2 -------------------
# copy openfold.tar.gz to /home/vscode
COPY openfold.tar.gz esm-main.tar.gz create-env.sh /home/vscode/

# install openfold conda env 
RUN tar -zxvf /home/vscode/openfold.tar.gz -C /home/vscode && \
    rm /home/vscode/openfold.tar.gz && \
    chown -R vscode:vscode /home/vscode/openfold && \
    chmod -R 777 /home/vscode/openfold && \
    cd /home/vscode/openfold && \
    mamba env create -f /home/vscode/openfold/environment.yml

# install esm-fold command
RUN zsh /home/vscode/create-env.sh

# copy esm-fold checkpoints
COPY --chmod=777 esm2_t36_3B_UR50D-contact-regression.pt esm2_t36_3B_UR50D.pt esmfold_3B_v1.pt /root/.cache/torch/hub/checkpoints/

# change permission 
# RUN sudo chmod -R 777 /home/vscode/.cache/torch/hub/checkpoints
# COPY run-esm-fold.sh /home/vscode/run-esm-fold.sh

# RUN sudo chmod -R 777 /root/.cache/torch/hub/checkpoints
COPY run-esm-fold.sh /root/run-esm-fold.sh

COPY run-esm.py /root/run-esm.py

# WORKDIR /home/vscode
WORKDIR /root

ENTRYPOINT ["zsh", "run-esm-fold.sh"]
