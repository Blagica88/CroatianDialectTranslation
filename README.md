# CroationDialectTranslation

This repository contains the implementation of an Unsupervised NMT model to translate from Croation Dialect to standard Croation language,Without using a single parallel sentence during training.

Link to the paper: 



## Running Unsupervised NMT
### Dataset and its creation

### Pre-processing of the data
To start with the preprocessing just run:
./get_data.sh

The script will successively 
install tools (Moses scripts, fastBPE ,fastText ),
tokenize monolingual data, apply BPE codes on monolingual data and on the parallel data which is for evaluation, than extract training vocabulary and will binarize the monolingual and parallel data


### Integrated cross-lingual embeddings


### Utilization of the UNMT architecture to build our model

