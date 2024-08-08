#!/bin/bash


OUTPUT=$1
ZERO_STAGE=$2
if [ "$OUTPUT" == "" ]; then
    OUTPUT=./outs/s2_random_mlp_seed_42
fi
if [ "$ZERO_STAGE" == "" ]; then
    ZERO_STAGE=1                    # lets use zero_stage 1 for now
fi
mkdir -p $OUTPUT

master_port=$((RANDOM % 5000 + 20000))
# add offload add master_port if socket error
deepspeed --include=localhost:0,1,2,3 \
    --master_port $master_port finetune.py \
    --offload \
    --model_name_or_path yahma/llama-7b-hf \
    --per_device_train_batch_size 16 \
    --per_device_eval_batch_size 16 \
    --max_seq_len 2048 \
    --learning_rate 2e-4 \
    --weight_decay 0. \
    --num_train_epochs 3 \
    --dtype bf16 \
    --gradient_accumulation_steps 1 \
    --lr_scheduler_type linear \
    --num_warmup_steps 100 \
    --seed 42 \
    --zero_stage $ZERO_STAGE \
    --deepspeed \
    --gradient_checkpointing \
    --save_interval 5000 \
    --instruction_type single \
    --only_optimize_s2 \
    --val_set_size 120 \
    --eval_step 80 \
    --s2 \
    --q_ratio 0.0 \
    --v_ratio 0.0 \
    --u_ratio 0.013 \
    --d_ratio 0.013 \
    --ug \
    --data_path  ./LLM-Adapters/ft-training_set/commonsense_170k.json  \
    --eval_delay 0.5 \
    --output_dir $OUTPUT 2> >(tee $OUTPUT/err.log >&2) | tee $OUTPUT/training.log \

