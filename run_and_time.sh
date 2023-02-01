#!/bin/bash
set -e

# runs benchmark and reports time to convergence
# to use the script:
#   run_and_time.sh <random seed 1-5> <num_gpus>

SEED=${1:--1} 
NUM_GPUS=${2:-1}
BATCH_SIZE=${3:-2}
NUM_WORKERS=${4:-1}
SKIP_STEP_7=${5:-""}

if [ ! -z $SKIP_STEP_7 ]
then
  SKIP_STEP_7="--skip_step_7"
fi

MAX_EPOCHS=20
QUALITY_THRESHOLD="0.908"
START_EVAL_AT=10
EVALUATE_EVERY=5
LEARNING_RATE="0.8"
LR_WARMUP_EPOCHS=0
DATASET_DIR="/data"
GRADIENT_ACCUMULATION_STEPS=1
SAVE_CKPT_PATH="/ckpts"

if [ -d ${DATASET_DIR} ]
then
    # start timing
    start=$(date +%s)
    start_fmt=$(date +%Y-%m-%d\ %r)
    echo "STARTING TIMING RUN AT $start_fmt"

# CLEAR YOUR CACHE HERE
  python -c "
from mlperf_logging.mllog import constants
from runtime.logging import mllog_event
mllog_event(key=constants.CACHE_CLEAR, value=True)"

# ddplaunch=$(python -c "from os import path; import torch; print(path.join(path.dirname(torch.__file__), 'distributed', 'launch.py'))")

horovodrun -np ${NUM_GPUS} python main.py \
    --data_dir ${DATASET_DIR} \
    --epochs ${MAX_EPOCHS} \
    --evaluate_every ${EVALUATE_EVERY} \
    --start_eval_at ${START_EVAL_AT} \
    --quality_threshold ${QUALITY_THRESHOLD} \
    --batch_size ${BATCH_SIZE} \
    --optimizer sgd \
    --ga_steps ${GRADIENT_ACCUMULATION_STEPS} \
    --learning_rate ${LEARNING_RATE} \
    --seed ${SEED} \
    --lr_warmup_epochs ${LR_WARMUP_EPOCHS} \
    --save_ckpt_path ${SAVE_CKPT_PATH} \
    --num_workers ${NUM_WORKERS} \
    $SKIP_STEP_7

	# end timing
	end=$(date +%s)
	end_fmt=$(date +%Y-%m-%d\ %r)
	echo "ENDING TIMING RUN AT $end_fmt"


	# report result
	result=$(( $end - $start ))
	result_name="image_segmentation"


	echo "RESULT,$result_name,$SEED,$result,$USER,$start_fmt"
else
	echo "Directory ${DATASET_DIR} does not exist"
fi