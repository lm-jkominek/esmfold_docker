# esmfold_docker
Dockerfile for an image running ESMFold

The repo is a clone of https://github.com/biochunan/esmfold-docker-image, but with the author's Google Docs downloads replaced by our cloud storage 

The VM running the image (either done manually or spin-up automatically) must have CUDA and an Nvidia driver installed. This can be done manually, or using a base environment that already has those such as the Debian-based "Deep Learning VM with CUDA 11.3" on GCP (the VM might ask you whether to install the driver on first login). CUDA 11.8 wasn't tested but should work just fine, whereas CUDA 12+ might not work.  
