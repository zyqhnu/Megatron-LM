bash examples/foundational_qa/generate_multijob_ckpt_step_same_format_cross_fqa.sh ford_tasb_ftmsmarcominilm_chunkbysents150_benzlandroverford_retrieved 43b greedy test  0 250 4500 5 qa_blendv2_gpt_1e-8_same_format_ctx1_43b_64_3e-7
bash examples/foundational_qa/generate_multijob_ckpt_step_same_format_cross_fqa.sh att_dragon_retriever_msmarcominilm_reranker_chunkbysents300_retrieved 43b greedy test  0 250 4500 5 qa_blendv2_gpt_1e-8_same_format_ctx1_43b_64_3e-7

bash examples/foundational_qa/generate_multijob_ckpt_step_same_format_cross_fqa.sh ford_tasb_ftmsmarcominilm_chunkbysents150_benzlandroverford_retrieved 43b greedy test  0 250 4500 5 qa_blendv2_gpt_1e-8_unbiased_cuckoo_pp1_same_format_ctx1_43b_64_3e-7
bash examples/foundational_qa/generate_multijob_ckpt_step_same_format_cross_fqa.sh att_dragon_retriever_msmarcominilm_reranker_chunkbysents300_retrieved 43b greedy test  0 250 4500 5 qa_blendv2_gpt_1e-8_unbiased_cuckoo_pp1_same_format_ctx1_43b_64_3e-7
