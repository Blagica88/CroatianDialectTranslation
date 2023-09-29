# CroationDialectTranslation

This repository contains the implementation of an Unsupervised NMT model to translate from Croation Dialect to standard Croation language without using a single parallel sentence during training.

Link to the paper: https://ieeexplore.ieee.org/document/10159848



## Running Unsupervised NMT
### Dataset <br>
The monolingual dataset of standard Croatian and the dialect dataset, which we created from scratch, are both contained in the data/mono folder. <br>
The parallel sentences for evaluation that were translated from croation dialects into Croatian standard language by a human linguist are stored in the data/para/dev folder.

### Pre-processing of the data
To start with the preprocessing just run: <br>
./get_data.sh

The script will successively 
install tools (Moses scripts, fastBPE, fastText),
tokenize monolingual data, apply BPE codes on monolingual data and on the parallel data which is for evaluation, than extract training vocabulary and will binarize the monolingual and parallel data.


### Cross-lingual embeddings
Two approaches were applied. The first one was a fastText model trained on the concatenated and shuffled dataset created from the two monolingual datasets, the dialect one, and the one with the standardized language. The other approach is based on MUSE where the monolingual fastText embeddings are aligned in a common space to obtain multilingual word embeddings. The alignment is done using the unsupervised approach and only utilizes a bilingual dictionary of pairs of dialect words and standard words for the evaluation. The MUSE-aligned centred embeddings between the two languages are learnt using adversarial training and (iterative) Procrustes refinement. The second approach acquired better results so those MUSE cross-lingual embeddings are used in the training phase of the unsupervised translation model.


### Train the UNMT model
Finally, you can train the model using the following command: <br>
./run_final.sh <br>

## Reference
@INPROCEEDINGS{10159848,<br>
  author={Penkova, Blagica and Mitreska, Maja and Ristov, Kiril and Mishev, Kostadin and Simjanoska, Monika},<br>
  booktitle={2023 46th MIPRO ICT and Electronics Convention (MIPRO)}, <br>
  title={Learning Translation Model to Translate Croatian Dialects to Modern Croatian Language}, <br>
  year={2023},<br>
  volume={},<br>
  number={},<br>
  pages={1083-1088},<br>
  doi={10.23919/MIPRO57284.2023.10159848}}<br>

## Acknlowledgments and References
This repository borrowed from these repositories: <br>
https://github.com/NLP2CT/Unsupervised_Dialect_Translation.git <br>
https://github.com/facebookresearch/UnsupervisedMT <br>
<br>
<br>
If you have any questions or feedback, you can contact us at penkovab@yahoo.com

