# coding=utf-8
# Copyright (c) 2020, NVIDIA CORPORATION.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Inference API."""
import numpy as np
import torch
from megatron.core import mpu
from megatron import print_rank_0, get_retro_args, get_args
from .communication import broadcast_float_list
from .generation import (
    generate_tokens_probs_and_return_on_first_stage,
    score_and_return_on_first_stage)
from .retro_generation import (
    retro_generate_tokens_probs_and_return_on_first_stage,
    retro_beam_search_and_return_on_first_stage)
from .tokenization import (
    tokenize_prompts,
    detokenize_generations)


def retro_generate_and_post_process(model,
                              prompts=None,
                              neighbours_array=None,
                              tokens_to_generate=0,
                              return_output_log_probs=False,
                              top_k_sampling=0,
                              top_p_sampling=0.0,
                              temperature=1.0,
                              add_BOS=False,
                              use_eod_token_for_early_termination=True,
                              random_seed=-1,
                              logits_mask=None):
    """Run inference and post-process outputs, i.e., detokenize,
    move to cpu and convert to list."""

    # Main inference.
    tokens, lengths, output_log_probs = retro_generate(
        model,
        prompts=prompts,
        neighbours_array=neighbours_array,
        tokens_to_generate=tokens_to_generate,
        return_output_log_probs=return_output_log_probs,
        top_k_sampling=top_k_sampling,
        top_p_sampling=top_p_sampling,
        temperature=temperature,
        add_BOS=add_BOS,
        use_eod_token_for_early_termination=use_eod_token_for_early_termination,
        random_seed=random_seed,
        logits_mask=logits_mask)

    # Only post-process on first stage.
    if mpu.is_pipeline_first_stage():
        tokens, prompts_plus_generations, prompts_plus_generations_segments = \
            detokenize_generations(tokens, lengths, True)

        if return_output_log_probs:
            output_log_probs = output_log_probs.cpu().numpy().tolist()
            for i, (prob, seg) in enumerate(zip(output_log_probs, prompts_plus_generations_segments)):
                output_log_probs[i] = prob[:len(seg) - 1]

        return prompts_plus_generations, prompts_plus_generations_segments, \
               output_log_probs, tokens

    return None


def retro_generate(model,
             prompts=None,
             neighbours_array=None,
             tokens_to_generate=0,
             return_output_log_probs=False,
             top_k_sampling=0,
             top_p_sampling=0.0,
             temperature=1.0,
             add_BOS=False,
             use_eod_token_for_early_termination=True,
             stop_on_double_eol=False,
             stop_on_eol=False,
             random_seed=-1,
             logits_mask=None):
    """Given prompts and input parameters, run inference and return:
       tokens: prompts plus the generated tokens.
       lengths: length of the prompt + generations. Note that we can
           discard tokens in the tokens tensor that are after the
           corresponding length.
       output_log_probs: log probs of the tokens.
    """

    # Make sure input params are avaialble to all ranks.
    values = [tokens_to_generate,
              return_output_log_probs,
              top_k_sampling, top_p_sampling,
              temperature, add_BOS, use_eod_token_for_early_termination,
              stop_on_double_eol,
              stop_on_eol,
              random_seed]
    values_float_tensor = broadcast_float_list(10, float_list=values)
    tokens_to_generate = int(values_float_tensor[0].item())
    return_output_log_probs = bool(values_float_tensor[1].item())
    top_k_sampling = int(values_float_tensor[2].item())
    top_p_sampling = values_float_tensor[3].item()
    temperature = values_float_tensor[4].item()
    add_BOS = bool(values_float_tensor[5].item())
    use_eod_token_for_early_termination = bool(values_float_tensor[6].item())
    stop_on_double_eol = bool(values_float_tensor[7].item())
    stop_on_eol = bool(values_float_tensor[8].item())
    random_seed = int(values_float_tensor[9].item())

    if random_seed != -1:
        torch.random.manual_seed(random_seed)

    # Tokenize prompts and get the batch.
    # Note that these tensors are broadcaseted to all ranks.
    if torch.distributed.get_rank() == 0:
        assert prompts is not None

    # print_rank_0(prompts)
    context_tokens_tensor, context_length_tensor = tokenize_prompts(
        prompts=prompts, tokens_to_generate=tokens_to_generate, add_BOS=add_BOS)
    # print_rank_0(context_tokens_tensor)
    # print_rank_0(context_length_tensor)

    retro_args = get_retro_args()
    args = get_args()
    r = retro_args.retro_gpt_retrieved_length
    l = int(np.ceil(min(args.max_position_embeddings, context_tokens_tensor.size(1)) / retro_args.retro_gpt_chunk_length))
    # print("neighbours_array:", neighbours_array.shape)
    if torch.distributed.get_rank() == 0:
        neighbours_array = neighbours_array.reshape(1, args.retro_num_neighbors, r).repeat(l, axis=0)  ## dim (l, k, r)
    # print("l:", l)
    # print("neighbor tokens shape:", neighbours_array.shape)

    if tokens_to_generate == 0:
        return score_and_return_on_first_stage(
            model, context_tokens_tensor, context_length_tensor)

    # Main inference function.
    # Note that the outputs are available on the first stage.
    return retro_generate_tokens_probs_and_return_on_first_stage(
        model, context_tokens_tensor, context_length_tensor,
        neighbours_array=neighbours_array,
        return_output_log_probs=return_output_log_probs,
        top_k=top_k_sampling,
        top_p=top_p_sampling,
        temperature=temperature,
        use_eod_token_for_early_termination=use_eod_token_for_early_termination,
        stop_on_double_eol=stop_on_double_eol,
        stop_on_eol=stop_on_eol,
        logits_mask=logits_mask)

def retro_beam_search_and_post_process(model,
                                 prompts=None,
                                 neighbours_array=None,
                                 tokens_to_generate=0,
                                 beam_size=0,
                                 add_BOS=False,
                                 stop_token=50256,
                                 num_return_gen=1,
                                 length_penalty=1):
    """Run beam search and post-process outputs, i.e., detokenize,
    move to cpu and convert to list."""

    # Main inference.
    tokens, scores = retro_beam_search(model,
                                 prompts=prompts,
                                 neighbours_array=neighbours_array,
                                 tokens_to_generate=tokens_to_generate,
                                 beam_size=beam_size,
                                 add_BOS=add_BOS,
                                 stop_token=stop_token,
                                 num_return_gen=num_return_gen,
                                 length_penalty=length_penalty)
    # Only post-process on first stage.
    if mpu.is_pipeline_first_stage():
        lengths = tokens.size(1)*torch.ones(beam_size, dtype=torch.int64, device=torch.cuda.current_device()) 
        tokens, prompts_plus_generations, prompts_plus_generations_segments = detokenize_generations(tokens, lengths, True)
        scores = scores.cpu().numpy().tolist()
        return prompts_plus_generations, prompts_plus_generations_segments, scores

    return None

def retro_beam_search(model, prompts=None, neighbours_array=None, tokens_to_generate=0, beam_size=0, add_BOS=False, stop_token=50256, num_return_gen=1, length_penalty=1):
    # Make sure input params are avaialble to all ranks.
    values = [tokens_to_generate,
              beam_size,
              add_BOS,
              stop_token,
              num_return_gen,
              length_penalty]
    values_float_tensor = broadcast_float_list(6, float_list=values)
    tokens_to_generate = int(values_float_tensor[0].item())
    beam_size = int(values_float_tensor[1].item())
    add_BOS = bool(values_float_tensor[2].item())
    stop_token = int(values_float_tensor[3].item())
    num_return_gen = int(values_float_tensor[4].item())
    length_penalty = values_float_tensor[5].item()

    context_tokens_tensor, context_length_tensor = tokenize_prompts(
        prompts=prompts, tokens_to_generate=tokens_to_generate, add_BOS=add_BOS)
    
    return retro_beam_search_and_return_on_first_stage(model, neighbours_array, context_tokens_tensor, context_length_tensor, 
            beam_size, stop_token=stop_token, num_return_gen=num_return_gen, length_penalty=length_penalty)