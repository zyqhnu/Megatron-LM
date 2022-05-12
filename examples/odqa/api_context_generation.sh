#!/bin/bash

# pip install transformers==4.10.0 --use-feature=2020-resolver

export CUDA_VISIBLE_DEVICES=0

WORLD_SIZE=1

DISTRIBUTED_ARGS="--nproc_per_node $WORLD_SIZE \
                  --nnodes 1 \
                  --node_rank 0 \
                  --master_addr localhost \
                  --master_port 6000 \
                  "

CHECKPOINT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/mpatwary/checkpoints/gpt3/gpt3-357m #(e.g., /357m)
VOCAB_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/mpatwary/checkpoints/gpt3/gpt3-357m/gpt2-vocab.json #(e.g., /gpt2-vocab.json)
MERGE_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/mpatwary/checkpoints/gpt3/gpt3-357m/gpt2-merges.txt #(e.g., /gpt2-merges.txt)

# MEGATRON_API='http://10.14.74.235:5000/api'
MEGATRON_API='http://localhost:12345/api'

# # DPR_MODEL_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/mpatwary/zihan/checkpoints/dpr_wow_ctrl/best_question_encoder.pt

# export EXP_NAME='nq_k0_357m'

export ENCODED_CTX_FILE=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/NQ/encoded_ctx_files_all_multisetdpr_queryctx.pickle
INPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/NQ/test.json
PROMPT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/NQ/train.json
INPUT_PATH_NEW=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/retrieval/predictions/dpr/nq/test.json
# OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/output_answer_generations_k10_357m_withnewnewGPTPrefix_l10_nogolden_withcontext_norandom_shift0_multisetdpr_qc.txt
# OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/output_answer_generations_k10_357m_gc_multisetdpr_queryctx_p0.9_rnd1.txt  # this means we fix all other parameters
# GEN_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/GenCTX/generated_context_k10_357m_gc_multisetdpr_queryctx_p0.9_rnd1.txt
# TOPK_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/analysi_result/topk_context_k10_357m_multisetdpr_queryctx_p0.9_rnd1.json
# OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/output_answer_generations_k10_1.3b_gc_357m_multisetdpr_queryctx_p0.9_rnd1.txt  # this means we fix all other parameters
# GEN_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/GenCTX/generated_context_k10_1.3b_gc_multisetdpr_queryctx_p0.9_rnd1.txt
# TOPK_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/analysi_result/topk_context_k10_1.3b_multisetdpr_queryctx_p0.9_rnd1.json
# OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/qg/output_answer_generations_k10_357m_gc_multisetdpr_queryctx_p0.9_test1.3b_fewshot.txt  # this means we fix all other parameters
# GEN_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/GenCTX/qg/generated_context_k10_357m_gc_multisetdpr_queryctx_p0.9_test1.3b_fewshot.txt
# TOPK_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/analysi_result/qg/topk_context_k10_357m_multisetdpr_queryctx_p0.9_test1.3b_fewshot.json

# OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/qg/output_answer_generations_k10_357m_gc_multisetdpr_queryctx_p0.9_fewshot.txt  # this means we fix all other parameters
# GEN_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/GenCTX/qg/generated_context_k10_357m_gc_multisetdpr_queryctx_p0.9_fewshot.txt
# TOPK_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/analysi_result/qg/topk_context_k10_357m_multisetdpr_queryctx_p0.9_fewshot.json

# using the megatron API
OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/output_answer_generations_k10_530b_gc_multisetdpr_queryctx_p0.9_rnd1.txt  # this means we fix all other parameters
GEN_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/GenCTX/api_generated_context_k10_530b_gc_multisetdpr_queryctx_p0.9_rnd1_2.txt
# TOPK_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/analysi_result/topk_context_k10_530b_multisetdpr_queryctx_p0.9_rnd1.json
CTX_PROMPT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/CTX_PROMPT/context_prompt_multisetdpr_queryctx.txt

# export EXP_NAME='tqa_k1_357m'
# INPUT_PATH_NEW=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/retrieval/predictions/dpr/triviaQA/test.json
# # # # export ENCODED_CTX_FILE=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/TQA/encoded_ctx_files_all_multisetdpr_queryctx_traingoodk0.pickle
# export ENCODED_CTX_FILE=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/TQA/encoded_ctx_files_all_multisetdpr_queryctx.pickle
# # INPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/TQA/test.json
# PROMPT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/TQA/train.json
# # # # # PROMPT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/TQA/train_good_examples.json
# # OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/TQA/output_answer_generations_k10_357m_withnewnewGPTPrefix_l10_nogolden_withcontext_norandom_multisetdpr_qc.txt
# # OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/TQA/output_answer_generations_k10_357m_gc_multisetdpr_queryctx_p0.9_11313_rmduplicatectx.txt  
# # GEN_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/TQA/GenCTX/generated_context_k10_357m_multisetdpr_queryctx_p0.9_11313_rmduplicatectx.txt
# # TOPK_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/TQA/analysi_result/topk_context_k10_357m_multisetdpr_queryctx_p0.9_11313_rmduplicatectx.json
# OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/TQA/qg/output_answer_generations_k10_357m_gc_multisetdpr_queryctx_p0.9_fewshot.txt  
# GEN_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/TQA/GenCTX/qg/generated_context_k10_357m_multisetdpr_queryctx_p0.9_fewshot.txt
# TOPK_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/TQA/analysi_result/qg/topk_context_k10_357m_multisetdpr_queryctx_p0.9_fewshot.json


# export EXP_NAME='wq_k1_357m'
# INPUT_PATH_NEW=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/retrieval/predictions/dpr/WebQuestions/WebQuestions-test.txt
# ENCODED_CTX_FILE=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/NQ/encoded_ctx_files_all.pickle
# PROMPT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/NQ/train.json 
# INPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/WQ/WebQuestions-test.txt
# # PROMPT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/WQ/WebQuestions-train.txt 
# # OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/WQ/output_answer_generations_k0_357m_withnewnewGPTPrefix_l10_nogolden_withcontext_norandom_nq.txt 
# OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/WQ/output_answer_generations_k10_357m_gc_nq.txt 
# GEN_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/WQ/GenCTX/generated_context_k10_357m_nq.txt

# PIQA dataset
# export EXP_NAME='k0_357m_l50_withgptneostyle_p0.0k1t1.0_new'
# INPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/PIQA/valid.jsonl #\  (the label file is valid-labels.lst)
# PROMPT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/PIQA/train.jsonl #\(the label file is train-labels.lst)
# OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/PIQA/output_answer_generations_${EXP_NAME}.txt 

random_seed=$RANDOM
echo $random_seed

python3 ./tasks/odqa/context_gen_api.py \
        --micro-batch-size 1 \
        --input-file ${INPUT_PATH} \
        --output-file ${OUTPUT_PATH} \
        --prompt-file ${PROMPT_PATH} \
        --out-seq-length 10 \
        --top-p-sampling 0.0 \
        --top-k-sampling 1 \
        --temperature 1.0 \
        --is-context-generated \
        --save-context-path ${GEN_CTX_PATH} \
        --api-prompt \
        --megatron-api-url ${MEGATRON_API} \
        --save-context-prompt-path ${CTX_PROMPT_PATH} \
        --random-seed 2345 \


# CHECKPOINT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/mpatwary/checkpoints/gpt3/gpt3-1.3b/ #(e.g., /357m)
# VOCAB_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/mpatwary/checkpoints/gpt3/gpt3-357m/gpt2-vocab.json #(e.g., /gpt2-vocab.json)
# MERGE_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/mpatwary/checkpoints/gpt3/gpt3-357m/gpt2-merges.txt #(e.g., /gpt2-merges.txt)

# export EXP_NAME='nq_k64_1.3b'
# # export ENCODED_CTX_FILE=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/NQ/encoded_ctx_files_all_1.3b.pickle
# export ENCODED_CTX_FILE=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/NQ/encoded_ctx_files_all_multisetdpr_queryctx.pickle

# INPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/NQ/test.json
# PROMPT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/NQ/train.json 
# # OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/output_answer_generations_k0_1.3b_withnewnewGPTPrefix_l10_nogolden_withcontext_norandom_shift1.txt 
# OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/output_answer_generations_k10_1.3b_gc_multisetdpr_queryctx_p0.9_rnd1.txt  
# GEN_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/GenCTX/generated_context_k10_1.3b_gc_multisetdpr_queryctx_p0.9_rnd1.txt
# TOPK_CTX_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/NQ/analysi_result/topk_context_k10_1.3b_multisetdpr_queryctx_p0.9_rnd1.json

# export EXP_NAME='tqa_k0_1.3b'
# INPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/TQA/test.json
# # INPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/TQA/dev.json
# PROMPT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/TQA/train.json 
# OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/TQA/output_answer_generations_k0_1.3b_withnewnewGPTPrefix_l10.txt 

# export EXP_NAME='wq_k1_357m'
# INPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/WQ/WebQuestions-test.txt
# PROMPT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/WQ/WebQuestions-train.txt 
# OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/WQ/output_answer_generations_k0_1.3b_withnewnewGPTPrefix_l10.txt 


# export EXP_NAME='piqa_k1_357m'
# INPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/PIQA/valid.jsonl #\  (the label file is valid-labels.lst)
# PROMPT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/open_domain_data/PIQA/train.jsonl #\(the label file is train-labels.lst)
# OUTPUT_PATH=/gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/PIQA/output_answer_generations_k0_1.3b_l50_withgptneostyle.txt 


# python -m torch.distributed.launch $DISTRIBUTED_ARGS ./tasks/odqa/main.py \
#         --num-layers 24 \
#         --hidden-size 2048 \
#         --num-attention-heads 32 \
#         --seq-length 2048 \
#         --max-position-embeddings 2048 \
#         --micro-batch-size 16 \
#         --vocab-file ${VOCAB_PATH} \
#         --merge-file ${MERGE_PATH} \
#         --load ${CHECKPOINT_PATH} \
#         --fp16 \
#         --DDP-impl torch \
#         --tokenizer-type GPT2BPETokenizer \
#         --input-file ${INPUT_PATH_NEW} \
#         --output-file ${OUTPUT_PATH} \
#         --prompt-file ${PROMPT_PATH} \
#         --num-prompt-examples 10 \
#         --out-seq-length 10 \
#         --prompt-format 'ours' \
#         --top-p-sampling 0.0 \
#         --top-k-sampling 1 \
#         --temperature 1.0 \
#         --encoded-ctx-files ${ENCODED_CTX_FILE} \
#         --task ODQA-CONTEXT-GEN-PROMPT \
#         --with-context \
#         --shift-steps 0 \
#         --use-golden \
#         --emb-type 'query_ctx' \
#         --is-context-generated \
#         --save-context-path ${GEN_CTX_PATH} \
#         --query-type 'question' \
#         --save-topk-context-path ${TOPK_CTX_PATH} \
#         --random-seed 4444 \
#         --question-generation \

        # --is-random \
        # --use-golden \


# NOTE: If you use api for the model generation, please use 
# the "--api-prompt" flag (setting this value as True). 
# 