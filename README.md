# esmfold_docker
Dockerfile for an image running ESMFold

# Notes
The repo is a clone of https://github.com/biochunan/esmfold-docker-image, but with the author's Google Docs downloads replaced by our cloud storage. 

Before building, you need to download 5 files from the **gs://ce-resources/esmfold_data/** bucket (esm-main.tar.gz,esm2_t36_3B_UR50D-contact-regression.pt,esm2_t36_3B_UR50D.pt,esmfold_3B_v1.pt, and openfold.tar.gz) and place them in the same directory as the Dockerfile to be part of the build env (you can also edit the Dockerfile to pull those directly from the cloud, if desired).

The image can take about 30-40 minutes to build and ends up being about 30-40 GBs in size, so very large (about 20% of that are the model weights). It doesn't affect performance, but worth keeping that in mind if ingress/egress is involved.  

# Requirements
The VM running the image (either done manually or spin-up automatically) must have CUDA and an Nvidia driver installed. This can be done manually, or using a base environment that already has those such as the Debian-based "Deep Learning VM with CUDA 11.3" on GCP (the VM might ask you whether to install the driver on first login). Host VM with CUDA 11.8 or 12+ weren't tested but should work just fine.

This was tested using Nvidia L4 and A100 GPUs, but the code can also work without a GPU, although the CPU code is about 10x slower and not fully parallelized (uses only about 25-50% of cores available).

# Running the image

The information below is from the original repo. If the GPU runs out of memory (GPUs with 20GB of memory do that at about 600 residues, 40GB GPUs at 1000 residues), try progressively lower values of the `--chunk-size`, e.g. 512, 256, 128, 64, 32, 16.

### Help information 

Run the following command to see the help information of `esm-fold`:
```shell
$ docker run --rm esmfold:base --help 
```

stdout: 
```shell
usage: esm-fold [-h] -i FASTA -o PDB [-m MODEL_DIR]
                [--num-recycles NUM_RECYCLES]
                [--max-tokens-per-batch MAX_TOKENS_PER_BATCH]
                [--chunk-size CHUNK_SIZE] [--cpu-only] [--cpu-offload]

optional arguments:
  -h, --help            show this help message and exit
  -i FASTA, --fasta FASTA
                        Path to input FASTA file
  -o PDB, --pdb PDB     Path to output PDB directory
  -m MODEL_DIR, --model-dir MODEL_DIR
                        Parent path to Pretrained ESM data directory.
  --num-recycles NUM_RECYCLES
                        Number of recycles to run. Defaults to number used in
                        training (4).
  --max-tokens-per-batch MAX_TOKENS_PER_BATCH
                        Maximum number of tokens per gpu forward-pass. This
                        will group shorter sequences together for batched
                        prediction. Lowering this can help with out of memory
                        issues, if these occur on short sequences.
  --chunk-size CHUNK_SIZE
                        Chunks axial attention computation to reduce memory
                        usage from O(L^2) to O(L). Equivalent to running a for
                        loop over chunks of of each dimension. Lower values
                        will result in lower memory usage at the cost of
                        speed. Recommended values: 128, 64, 32. Default: None.
  --cpu-only            CPU only
  --cpu-offload         Enable CPU offloading
  --gpu-count           Number of GPUs to use concurrently (option added in this repo, not part of esm-fold). Default: 1
```

### Run ESMFold with fasta file as input 
```shell
$ docker run --rm --gpus all \
    -v ./example/input:/input \
    -v ./example/output:/output \
    esmfold:base \
    -i /input/1a2y-HLC.fasta -o /output > ./example/logs/pred.log 2>./example/logs/pred.err \
```
- `-i /input/1a2y-HLC.fasta`: input fasta file
- `-o /output`: path to output predicted structure 
- `> ./example/logs/pred.log 2>./example/logs/pred.err`: redirect stdout and stderr to log files
other flags 
- `--num-recycles NUM_RECYCLES`: Number of recycles to run. Defaults to number used in training (default is 4).
- `--max-tokens-per-batch MAX_TOKENS_PER_BATCH`: Maximum number of tokens per gpu forward-pass. This will group shorter sequences together for batched prediction. Lowering this can help with out of memory issues, if these occur on short sequences.
- `--chunk-size CHUNK_SIZE`: Chunks axial attention computation to reduce memory usage from O(L^2) to O(L). Equivalent to running a for loop over chunks of of each dimension. Lower values will result in lower memory usage at the cost of speed. Recommended values: 128, 64, 32. Default: None.
- `--cpu-only`: CPU only
- `--cpu-offload`: Enable CPU offloading

### Overwrite entrypoint 
If you want to overwrite the entrypoint, you can do so by adding the following to the end of the `docker run` command:
```shell
$ docker run --rm --gpus all --entrypoint "/bin/zsh" esmfold:base -c "echo 'hello world'"
```

### Test GPU 
```shell
$ docker run --rm --gpus all --entrypoint "nvidia-smi" esmfold:base 
```
