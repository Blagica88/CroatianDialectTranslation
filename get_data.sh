# Copyright (c) 2018-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#

set -e

#
# Data preprocessing configuration
#

N_MONO=53721      # number of monolingual sentences for each language
CODES=60000      # number of BPE codes
N_THREADS=48     # number of threads in data preprocessing
N_EPOCHS=10      # number of fastText epochs


#
# Initialize tools and data paths
#

# main paths
UMT_PATH=$PWD
TOOLS_PATH=$PWD/tools
DATA_PATH=$PWD/data
MONO_PATH=$DATA_PATH/mono
PARA_PATH=$DATA_PATH/para

# create paths
mkdir -p $TOOLS_PATH
mkdir -p $DATA_PATH
mkdir -p $MONO_PATH
mkdir -p $PARA_PATH

# moses
MOSES=$TOOLS_PATH/mosesdecoder
TOKENIZER=$MOSES/scripts/tokenizer/tokenizer.perl
NORM_PUNC=$MOSES/scripts/tokenizer/normalize-punctuation.perl
INPUT_FROM_SGM=$MOSES/scripts/ems/support/input-from-sgm.perl
REM_NON_PRINT_CHAR=$MOSES/scripts/tokenizer/remove-non-printing-char.perl

# fastBPE
FASTBPE_DIR=$TOOLS_PATH/fastBPE
FASTBPE=$FASTBPE_DIR/fast

# fastText
FASTTEXT_DIR=$TOOLS_PATH/fastText
FASTTEXT=$FASTTEXT_DIR/fasttext

# files full paths
SRC_RAW=$MONO_PATH/FINAL_DIALECT_DATASETT.txt
TGT_RAW=$MONO_PATH/croation_dataset_final4_32_53721.txt
SRC_TOK=$MONO_PATH/all.st.tok
TGT_TOK=$MONO_PATH/all.cr.tok
BPE_CODES=$MONO_PATH/bpe_codes
CONCAT_BPE=$MONO_PATH/all.st-cr.$CODES
SRC_BPE=$MONO_PATH/all.st.$CODES
TGT_BPE=$MONO_PATH/all.cr.$CODES
SRC_VOCAB=$MONO_PATH/vocab.st.$CODES
TGT_VOCAB=$MONO_PATH/vocab.cr.$CODES
FULL_VOCAB=$MONO_PATH/vocab.st-cr.$CODES
SRC_RAW_VALID=$PARA_PATH/dev/VALID_SET_ST.txt
TGT_RAW_VALID=$PARA_PATH/dev/VALID_SET_CR.txt
SRC_RAW_TEST=$PARA_PATH/dev/TEST_SET_ST.txt
TGT_RAW_TEST=$PARA_PATH/dev/TEST_SET_CR.txt
SRC_VALID=$PARA_PATH/dev/valid.st
TGT_VALID=$PARA_PATH/dev/valid.cr
SRC_TEST=$PARA_PATH/dev/tst.st
TGT_TEST=$PARA_PATH/dev/tst.cr

#
# Download and install tools
#

# Download Moses
cd $TOOLS_PATH
if [ ! -d "$MOSES" ]; then
  echo "Cloning Moses from GitHub repository..."
  git clone https://github.com/moses-smt/mosesdecoder.git
fi
echo "Moses found in: $MOSES"

# Download fastBPE
cd $TOOLS_PATH
if [ ! -d "$FASTBPE_DIR" ]; then
  echo "Cloning fastBPE from GitHub repository..."
  git clone https://github.com/glample/fastBPE
fi
echo "fastBPE found in: $FASTBPE_DIR"

# Compile fastBPE
cd $TOOLS_PATH
if [ ! -f "$FASTBPE" ]; then
  echo "Compiling fastBPE..."
  cd $FASTBPE_DIR
  g++ -std=c++11 -pthread -O3 fastBPE/main.cc -o fast
fi
echo "fastBPE compiled in: $FASTBPE"

# Download fastText
cd $TOOLS_PATH
if [ ! -d "$FASTTEXT_DIR" ]; then
  echo "Cloning fastText from GitHub repository..."
  git clone https://github.com/facebookresearch/fastText.git
fi
echo "fastText found in: $FASTTEXT_DIR"

# Compile fastText
cd $TOOLS_PATH
if [ ! -f "$FASTTEXT" ]; then
  echo "Compiling fastText..."
  cd $FASTTEXT_DIR
  make
fi
echo "fastText compiled in: $FASTTEXT"

# check number of lines
echo "$(wc -l < $SRC_RAW)"
echo "$(wc -l < $TGT_RAW)"
if ! [[ "$(wc -l < $SRC_RAW)" -eq "$N_MONO" ]]; then echo "ERROR: Number of lines doesn't match! Be sure you have $N_MONO sentences in your EN monolingual data."; exit; fi
if ! [[ "$(wc -l < $TGT_RAW)" -eq "$N_MONO" ]]; then echo "ERROR: Number of lines doesn't match! Be sure you have $N_MONO sentences in your FR monolingual data."; exit; fi

# tokenize data
if ! [[ -f "$SRC_TOK" && -f "$TGT_TOK" ]]; then
  echo "Tokenize monolingual data..."
  cat $SRC_RAW | $NORM_PUNC -l en | $TOKENIZER -l en -no-escape -threads $N_THREADS > $SRC_TOK
  cat $TGT_RAW | $NORM_PUNC -l en | $TOKENIZER -l en -no-escape -threads $N_THREADS > $TGT_TOK
fi
echo "ST monolingual data tokenized in: $SRC_TOK"
echo "CR monolingual data tokenized in: $TGT_TOK"

# learn BPE codes
if [ ! -f "$BPE_CODES" ]; then
  echo "Learning BPE codes..."
  $FASTBPE learnbpe $CODES $SRC_TOK $TGT_TOK > $BPE_CODES
fi
echo "BPE learned in $BPE_CODES"

# apply BPE codes
if ! [[ -f "$SRC_TOK.$CODES" && -f "$TGT_TOK.$CODES" ]]; then
  echo "Applying BPE codes..."
  $FASTBPE applybpe $SRC_TOK.$CODES $SRC_TOK $BPE_CODES
  $FASTBPE applybpe $TGT_TOK.$CODES $TGT_TOK $BPE_CODES
fi
echo "BPE codes applied to ST in: $SRC_TOK.$CODES"
echo "BPE codes applied to CR in: $TGT_TOK.$CODES"

# extract vocabulary
if ! [[ -f "$SRC_VOCAB" && -f "$TGT_VOCAB" && -f "$FULL_VOCAB" ]]; then
  echo "Extracting vocabulary..."
  $FASTBPE getvocab $SRC_TOK.$CODES > $SRC_VOCAB
  $FASTBPE getvocab $TGT_TOK.$CODES > $TGT_VOCAB
  $FASTBPE getvocab $SRC_TOK.$CODES $TGT_TOK.$CODES > $FULL_VOCAB
fi
echo "ST vocab in: $SRC_VOCAB"
echo "CR vocab in: $TGT_VOCAB"
echo "Full vocab in: $FULL_VOCAB"

# binarize data
if ! [[ -f "$SRC_TOK.$CODES.pth" && -f "$TGT_TOK.$CODES.pth" ]]; then
  echo "Binarizing data..."
  $UMT_PATH/preprocess.py $FULL_VOCAB $SRC_TOK.$CODES
  $UMT_PATH/preprocess.py $FULL_VOCAB $TGT_TOK.$CODES
fi
echo "ST binarized data in: $SRC_TOK.$CODES.pth"
echo "CR binarized data in: $TGT_TOK.$CODES.pth"


# check valid and test files are here
if ! [[ -f "$SRC_RAW_VALID" ]]; then echo "$SRC_RAW_VALID is not found!"; exit; fi
if ! [[ -f "$TGT_RAW_VALID" ]]; then echo "$TGT_RAW_VALID is not found!"; exit; fi
if ! [[ -f "$SRC_RAW_TEST" ]]; then echo "$SRC_RAW_TEST is not found!"; exit; fi
if ! [[ -f "$TGT_RAW_TEST" ]]; then echo "$TGT_RAW_TEST is not found!"; exit; fi

echo "Tokenizing valid and test data..."
cat $SRC_RAW_VALID | $NORM_PUNC -l en | $REM_NON_PRINT_CHAR | $TOKENIZER -l en -no-escape -threads 1 > $SRC_VALID
cat $TGT_RAW_VALID | $NORM_PUNC -l en | $REM_NON_PRINT_CHAR | $TOKENIZER -l en -no-escape -threads 1 > $TGT_VALID
cat $SRC_RAW_TEST | $NORM_PUNC -l en | $REM_NON_PRINT_CHAR | $TOKENIZER -l en -no-escape -threads 1 > $SRC_TEST
cat $TGT_RAW_TEST | $NORM_PUNC -l en | $REM_NON_PRINT_CHAR | $TOKENIZER -l en -no-escape -threads 1 > $TGT_TEST



echo "Applying BPE to valid and test files..."
$FASTBPE applybpe $SRC_VALID.$CODES $SRC_VALID $BPE_CODES $SRC_VOCAB
$FASTBPE applybpe $TGT_VALID.$CODES $TGT_VALID $BPE_CODES $TGT_VOCAB
$FASTBPE applybpe $SRC_TEST.$CODES $SRC_TEST $BPE_CODES $SRC_VOCAB 
$FASTBPE applybpe $TGT_TEST.$CODES $TGT_TEST $BPE_CODES $TGT_VOCAB 

echo "Binarizing data..."
rm -f $SRC_VALID.$CODES.pth $TGT_VALID.$CODES.pth $SRC_TEST.$CODES.pth $TGT_TEST.$CODES.pth
$UMT_PATH/preprocess.py $FULL_VOCAB $SRC_VALID.$CODES
$UMT_PATH/preprocess.py $FULL_VOCAB $TGT_VALID.$CODES
$UMT_PATH/preprocess.py $FULL_VOCAB $SRC_TEST.$CODES
$UMT_PATH/preprocess.py $FULL_VOCAB $TGT_TEST.$CODES


# #
# Summary
#
echo ""
echo "===== Data summary"
echo "Monolingual training data:"
echo "    ST: $SRC_TOK.$CODES.pth"
echo "    CR: $TGT_TOK.$CODES.pth"
echo "Parallel validation data:"
echo "    ST: $SRC_VALID.$CODES.pth"
echo "    CR: $TGT_VALID.$CODES.pth"
echo "Parallel test data:"
echo "    ST: $SRC_TEST.$CODES.pth"
echo "    CR: $TGT_TEST.$CODES.pth"
echo ""


#
# Train fastText on concatenated embeddings
#

if ! [[ -f "$CONCAT_BPE" ]]; then
  echo "Concatenating source and target monolingual data..."
  cat $SRC_TOK.$CODES $TGT_TOK.$CODES | shuf > $CONCAT_BPE
fi
echo "Concatenated data in: $CONCAT_BPE"

if ! [[ -f "$SRC_BPE" ]]; then
  echo "Copying source data..."
  #echo $SRC_TOK.$CODES > "${SRC_BPE}"
  cat $SRC_TOK.$CODES > "$SRC_BPE"
fi
echo "Copied data in: $SRC_BPE"

if ! [[ -f "$TGT_BPE" ]]; then
  echo "Copying target data..."
  cat $TGT_TOK.$CODES > "$TGT_BPE"
fi
echo "Copied data in: $TGT_BPE"

if ! [[ -f "$SRC_BPE.vec" ]]; then
  echo "Training fastText on $SRC_BPE.vec..."
  $FASTTEXT skipgram -epoch $N_EPOCHS -minCount -1 -dim 512 -thread $N_THREADS -ws 5 -neg 10 -input $SRC_BPE -output $SRC_BPE
fi
echo "Stokavski embeddings in: $SRC_BPE.vec"

if ! [[ -f "$TGT_BPE.vec" ]]; then
  echo "Training fastText on $TGT_BPE.vec..."
  $FASTTEXT skipgram -epoch $N_EPOCHS -minCount -1 -dim 512 -thread $N_THREADS -ws 5 -neg 10 -input $TGT_BPE -output $TGT_BPE
fi
echo "Croatian embeddings in: $TGT_BPE.vec"


if ! [[ -f "$CONCAT_BPE.vec" ]]; then
  echo "Training fastText on $CONCAT_BPE..."
  $FASTTEXT skipgram -epoch $N_EPOCHS -minCount 0 -dim 512 -thread $N_THREADS -ws 5 -neg 10 -input $CONCAT_BPE -output $CONCAT_BPE
fi
echo "Cross-lingual embeddings in: $CONCAT_BPE.vec"
