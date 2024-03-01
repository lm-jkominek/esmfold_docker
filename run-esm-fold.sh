#!/bin/zsh 

# init conda
source $HOME/.zshrc 

mamba run -n py39-esmfold python run-esm.py $@

# activate py39-esmfold
# mamba activate py39-esmfold

# run esm-fold
# esm-fold $@


