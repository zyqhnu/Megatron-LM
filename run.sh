# qa blends: https://gitlab-master.nvidia.com/ADLR/megatron-lm/-/blob/main_sft/examples/foundational_qa/qa_blendv12.sh
# finetuning command: bash examples/foundational_qa/finetune_normal_lm.sh qa_blendv12 43b  64 3e-7 1 gpt_1e-8_conv_quiet_cockatoo_pp1
# all data under: /lustre/fsw/adlr/adlr-nlp/pengx/data/foundational_qa/s3_data/


bash examples/foundational_qa/finetune_normal_lm.sh qa_blendv12 2b  64 3e-7 1 pp1

# where is the quietcockatoo data?

# constant learning rate?

# how the training works?

bash examples/foundational_qa/sft_normal_lm.sh sft 2b   128 5e-6 1 pp1
bash examples/foundational_qa/sft_normal_lm.sh sft 43b  128 5e-6 1 pp1

# run for second time
bash examples/foundational_qa/sft_normal_lm.sh sft 43b  128 5e-6 1 pp1


# Phase II: QA-tuning
bash examples/foundational_qa/finetune_normal_lm.sh qa_blendv12 43b 64 3e-7 1 pp1  /lustre/fsw/adlr/adlr-nlp/boxinw/sft-megatron-lm/checkpoints/applications/sft_pp1_same_format_ctx1_43b_128_5e-6_bak

## generation

bash run_gen_blends.sha

## Evaluation

python tasks/foundational_QA/evaluate_f1_fqa.py