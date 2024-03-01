import os, sys, argparse, subprocess, copy
from collections import defaultdict
from Bio import SeqIO
# import esm
# import torch


parser = argparse.ArgumentParser()
parser.add_argument("-i","--fasta",help="Path to input FASTA file",required=True)
parser.add_argument("-o", "--pdb", help="Path to output PDB directory",required=True)
parser.add_argument("-m", "--model-dir",default=None,help="Parent path to Pretrained ESM data directory.")
parser.add_argument("--num-recycles",type=int,default=None,help="Number of recycles to run. Defaults to number used in training (4).")
parser.add_argument("--max-tokens-per-batch",type=int,default=1024,help="Maximum number of tokens per gpu forward-pass. This will group shorter sequences together for batched prediction. Lowering this can help with out of memory issues, if these occur on short sequences.")
parser.add_argument("--chunk-size",type=int,default=None,help="Chunks axial attention computation to reduce memory usage from O(L^2) to O(L). Equivalent to running a for loop over chunks of of each dimension. Lower values will result in lower memory usage at the cost of speed. Recommended values: 128, 64, 32. Default: None.")
parser.add_argument("--cpu-only", help="CPU only", action="store_true")
parser.add_argument("--cpu-offload", help="Enable CPU offloading", action="store_true")
parser.add_argument("-g","--gpu-count", help="Number to GPUs to run on in parallel", type=int,default=1)
args = parser.parse_args()

print(args)

seq_lengths = []
seqs_all = []
for s in SeqIO.parse(args.fasta, "fasta"):
	seqs_all.append(s)
	seq_lengths.append((s.id,len(str(s.seq))))
seq_lengths_sorted = sorted(seq_lengths, key=lambda x: x[1])

splits = []
for split in range(args.gpu_count):
	split_seq_list = seq_lengths_sorted[split::args.gpu_count]
	splits.append([s[0] for s in split_seq_list])

for i,split in enumerate(splits):
	seqs_to_write = []
	for seq in seqs_all:
		if seq.id in split:
			seq2 = copy.deepcopy(seq)
			seq2.description = ""
			seq2.name = ""
			seq2.title = ""
			seqs_to_write.append(seq2)
	SeqIO.write(seqs_to_write,"split"+str(i)+".fasta","fasta")

m_arg = []
if args.model_dir != None:
	m_arg = ["--model-dir",args.model_dir]
n_arg = []
if args.num_recycles != None:
	n_arg = ["--num-recycles",args.num_recycles]
token_arg = []
if args.max_tokens_per_batch != 1024:
	token_arg = ["--max-tokens-per-batch",args.max_tokens_per_batch]
chunk_arg = []
if args.chunk_size != None:
	chunk_arg = ["--chunk-size",args.chunk_size]
cpu_arg = []
if args.cpu_only == True:
	cpu_arg = ["--cpu-only"]
cpu_off_arg = []
if args.cpu_offload == True:
	cpu_off_arg = ["--cpu-offload"]

procs = []
for gpu in range(args.gpu_count):
	split_env = os.environ.copy()
	split_env["CUDA_VISIBLE_DEVICES"] = str(gpu)
	esm_cmd = ["esm-fold","--fasta","split"+str(gpu)+".fasta","--pdb",args.pdb]+m_arg+n_arg+token_arg+chunk_arg+cpu_arg+cpu_off_arg
	with open(args.pdb+"/split"+str(gpu)+"_out.log","w") as split_out, open(args.pdb+"/split"+str(gpu)+"_err.log","w") as split_err:
		procs.append(subprocess.Popen(esm_cmd, env=split_env, stdout=split_out, stderr=split_err))

for p in procs:
   p.communicate()
   