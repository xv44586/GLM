source config/model_blocklm_large_generation.sh
EXPERIMENT_NAME=${MODEL_TYPE}-cnndm-608
CHECKPOINT_PATH="/root/data/checkpoints"

MASTER_PORT=$(shuf -n 1 -i 10000-65535)
DISTRIBUTED_ARGS="--nproc_per_node 8 --nnodes 1 --node_rank 0 --master_addr localhost --master_port $MASTER_PORT"
DATESTR=$(date +"%m-%d-%H-%M")

TASK_NAME=cnn_dm
DATA_PATH="/root/data/cnn_dm"

TRAIN_ARGS="--epochs 0 \
            --batch-size 8 \
            --lr 3e-5 \
            --lr-decay-style linear \
            --warmup 0.06 \
            --weight-decay 1.0e-1
            --label-smoothing 0.1"

COMMON_ARGS="--save-interval 10000 \
             --log-interval 50 \
             --eval-interval 1000 \
             --eval-iters 100"

mkdir logs
python -m torch.distributed.launch $DISTRIBUTED_ARGS finetune_gpt2.py \
       --finetune \
       --experiment-name ${EXPERIMENT_NAME}_topk_penalty \
       --task ${TASK_NAME} \
       --data-dir ${DATA_PATH} \
       --save ${CHECKPOINT_PATH} \
       --checkpoint-activations \
       --src-seq-length 608 \
       --tgt-seq-length 160 \
       --min-tgt-length 55 \
       --length-penalty 2.0 \
       --no-repeat-ngram-size 3 \
       --num-beams 5 \
       --select-topk \
       --eval-batch-size 4 \
       --eval-valid \
       $MODEL_ARGS \
       $TRAIN_ARGS \
       $COMMON_ARGS \
       --load /root/data/checkpoints/generation-large-cnndm-608 \
       2>&1 | tee logs/log-${DATESTR}.txt