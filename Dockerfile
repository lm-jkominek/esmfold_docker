FROM nvidia/cuda:11.3.1-devel-ubuntu20.04 
# 11.3 required for openfold

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install zsh and ohmyzsh
RUN apt-get update && apt-get install -yq zsh sudo curl wget jq vim git-core gnupg locales && apt-get clean
# RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" || true
# Default powerline10k theme, no plugins installed
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)" -- \
    -t robbyrussell
RUN sudo chsh -s /bin/zsh

# credits: @pangyuteng
# refer to: https://gist.github.com/pangyuteng/f5b00fe63ac31a27be00c56996197597
# Use the above args during building https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG CONDA_VER=4.5.11
ARG OS_TYPE=x86_64
# Install miniconda to /miniconda
RUN curl -LO "http://repo.continuum.io/miniconda/Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh"
RUN bash Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh -p /miniconda -b
RUN rm Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh
ENV PATH=/miniconda/bin:${PATH}
RUN conda update -y conda

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN conda clean -a -y && pip cache purge

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
COPY openfold.tar.gz /home/vscode/openfold.tar.gz
COPY esm-main.tar.gz /home/vscode/esm-main.tar.gz
# RUN pip install gdown 
# add gdown to PATH 
ENV PATH="/home/vscode/.local/bin:${PATH}"
# RUN wget https://drive.google.com/uc?id=1PvZLs4zeh3g_JajIsbeQmhOewoI_Stll -O /home/vscode/openfold.tar.gz && \
#     wget https://drive.google.com/uc?id=1YE_CEOUc5FYxrEnNiQcLgttnNxUXqQj- -O /home/vscode/esm-main.tar.gz
COPY create-env.sh /home/vscode/create-env.sh

# install openfold conda env 
RUN tar -zxvf /home/vscode/openfold.tar.gz -C /home/vscode && \
    rm /home/vscode/openfold.tar.gz && \
    chown -R vscode:vscode /home/vscode/openfold && \
    chmod -R 777 /home/vscode/openfold && \
    cd /home/vscode/openfold && \
    conda env create -f /home/vscode/openfold/environment.yml

# install esm-fold command
RUN zsh /home/vscode/create-env.sh

# # copy esm-fold checkpoints
# COPY esm2_t36_3B_UR50D-contact-regression.pt  /home/vscode/.cache/torch/hub/checkpoints/esm2_t36_3B_UR50D-contact-regression.pt
# COPY esm2_t36_3B_UR50D.pt  /home/vscode/.cache/torch/hub/checkpoints/esm2_t36_3B_UR50D.pt
# COPY esmfold_3B_v1.pt  /home/vscode/.cache/torch/hub/checkpoints/esmfold_3B_v1.pt

COPY esm2_t36_3B_UR50D-contact-regression.pt  /root/.cache/torch/hub/checkpoints/esm2_t36_3B_UR50D-contact-regression.pt
COPY esm2_t36_3B_UR50D.pt  /root/.cache/torch/hub/checkpoints/esm2_t36_3B_UR50D.pt
COPY esmfold_3B_v1.pt  /root/.cache/torch/hub/checkpoints/esmfold_3B_v1.pt

# use gdown to download above files from google drive 
# RUN mkdir -p /home/vscode/.cache/torch/hub/checkpoints && \
    # wget https://drive.google.com/uc?id=1lW8CVTSzX8bwLxbM8lAu_qXQkrPZuSxA -O /home/vscode/.cache/torch/hub/checkpoints/esm2_t36_3B_UR50D-contact-regression.pt && \
    # wget https://drive.google.com/uc?id=1CHTS2cB8HrgayylwVB8tsrLKcpTqKFLx -O /home/vscode/.cache/torch/hub/checkpoints/esm2_t36_3B_UR50D.pt && \
    # wget https://drive.google.com/uc?id=1CQZdYpXI1pb55ro8hCEP37pMsG2_Dbul -O /home/vscode/.cache/torch/hub/checkpoints/esmfold_3B_v1.pt

# change permission 
# RUN sudo chmod -R 777 /home/vscode/.cache/torch/hub/checkpoints
# COPY run-esm-fold.sh /home/vscode/run-esm-fold.sh

RUN sudo chmod -R 777 /root/.cache/torch/hub/checkpoints
COPY run-esm-fold.sh /root/run-esm-fold.sh

# WORKDIR /home/vscode
WORKDIR /root

ENTRYPOINT ["zsh", "run-esm-fold.sh"]
