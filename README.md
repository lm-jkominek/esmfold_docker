# esmfold_docker
Dockerfile for an image running ESMFold

# Notes
The repo is a clone of https://github.com/biochunan/esmfold-docker-image, but with the author's Google Docs downloads replaced by our cloud storage.

The image can take about 30-40 minutes to build and ends up being about 30-40 GBs in size, so very large (about 20% of that are the model weights). It doesn't affect performance, but worth keeping that in mind if ingress/egress is involved.  

# Requirements
The VM running the image (either done manually or spin-up automatically) must have CUDA and an Nvidia driver installed. This can be done manually, or using a base environment that already has those such as the Debian-based "Deep Learning VM with CUDA 11.3" on GCP (the VM might ask you whether to install the driver on first login). CUDA 11.8 wasn't tested but should work just fine, whereas CUDA 12+ might not work.  

This was tested using Nvidia L4 and A100 GPUs, but the code can also work without a GPU, although the CPU code is about 10x slower and not fully parallelized, so only uses about 25-50% of cores available.
