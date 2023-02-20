# CroationDialectTranslation

This repository contains the implementation of an Unsupervised NMT model to translate from Croation Dialect to standard Croation language,Without using a single parallel sentence during training.

Link to the paper: 



## Running Unsupervised NMT
### Dataset <br>
The monolingual dataset of standard Croatian and the dialect dataset, which we created from scratch, are both contained in the data/mono folder. <br>
The parallel sentences for evaluation that were translated from croation dialects into Croatian by a human linguist are stored in the data/para/dev folder.

### Pre-processing of the data
To start with the preprocessing just run: <br>
./get_data.sh

The script will successively 
install tools (Moses scripts, fastBPE ,fastText ),
tokenize monolingual data, apply BPE codes on monolingual data and on the parallel data which is for evaluation, than extract training vocabulary and will binarize the monolingual and parallel data.


### Integrated cross-lingual embeddings
We did not train another fastText model on the concatenated and shuffled dataset created from the two monolingual datasets, the dialect one, and the one with the standardized language.We were using other approach approach which is based on MUSE where the monolingual fastText embeddings are aligned in a common space to obtain multilingual word embeddings. The alignment is done using the unsupervised approach and only utilizes a bilingual dictionary of pairs of dialect words and standard words for the evaluation. The MUSE-aligned centred embeddings between the two languages are learnt using adversarial training and (iterative) Procrustes refinement.


### Utilization of the UNMT architecture to build our model
Finally, you can train the model using the following command: <br>
./run_final.sh <br>

If you have any questions or feedback, you can contact me at blagica.penkova@ireason.com

