# coding=utf-8
# Copyright (c) 2019, NVIDIA CORPORATION.  All rights reserved.
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

"""Pretrain GPT2"""

import os

import torch

from megatron import get_args
from megatron import get_timers
from megatron import get_tokenizer
from megatron import mpu
from megatron import print_rank_0
from megatron.data.gpt2_dataset import GPT2Dataset
from megatron.model import GPT2Model
from megatron.training import pretrain
from megatron.utils import get_ltor_masks_and_position_ids
from megatron.utils import make_data_loader
from megatron.utils import reduce_losses


def model_provider():
    """Build the model."""
    args = get_args()

    print_rank_0('building GPT2 model ...')
    model = GPT2Model(num_tokentypes=0, parallel_output=True)

    return model


def get_batch(data_iterator):
    """Generate a batch"""
    args = get_args()
    tokenizer = get_tokenizer()

    # Items and their type.
    keys = ['text']
    datatype = torch.int64

    # Broadcast data.
    if data_iterator is not None:
        data = next(data_iterator)
    else:
        data = None
    data_b = mpu.broadcast_data(keys, data, datatype)

    # Unpack.
    tokens_ = data_b['text'].long()
    labels = tokens_[:, 1:].contiguous()
    tokens = tokens_[:, :-1].contiguous()

    # Get the masks and postition ids.
    attention_mask, loss_mask, position_ids = get_ltor_masks_and_position_ids(
        tokens,
        tokenizer.eod,
        args.reset_position_ids,
        args.reset_attention_mask,
        args.eod_mask_loss,
        args.fp16)

    return tokens, labels, loss_mask, attention_mask, position_ids


def forward_step(data_iterator, model):
    """Forward step."""
    timers = get_timers()

    # Get the batch.
    timers('batch generator').start()
    tokens, labels, loss_mask, attention_mask, position_ids = get_batch(
        data_iterator)
    timers('batch generator').stop()

    # Forward model.
    output = model(tokens, position_ids, attention_mask)
    losses = mpu.vocab_parallel_cross_entropy(output.contiguous().float(),
                                              labels)
    loss_mask = loss_mask.view(-1)
    loss = torch.sum(losses.view(-1) * loss_mask) / loss_mask.sum()

    # Reduce loss for logging.
    reduced_loss = reduce_losses([loss])

    return loss, {'lm loss': reduced_loss[0]}


def make_gpt2_dataloaders():
    """Build gpt2 dataloders."""
    args = get_args()

    # Input parameters.
    input_data_sizes_file = args.input_data_sizes_file
    seq_length = args.seq_length
    initial_seed = args.seed

    # Build the datasets.
    def _build_dataset(name):
        return GPT2Dataset(os.path.join(args.data_path, name),
                           args.input_data_sizes_file,
                           args.seq_length, args.seed)
    train_ds = _build_dataset('train')
    valid_ds = _build_dataset('valid')
    test_ds = _build_dataset('test')

    # Dataloaders
    train = make_data_loader(train_ds)
    valid = make_data_loader(valid_ds)
    test = make_data_loader(test_ds)

    args.do_train = False
    args.do_valid = False
    args.do_test = False

    if train is not None:
        args.do_train = True
    if valid is not None:
        args.do_valid = True
    if test is not None:
        args.do_test = True

    return (train, valid, test)


def get_train_val_test_data():
    """Load the data on rank zero and boradcast number of tokens to all GPUS."""
    args = get_args()

    (train_data, val_data, test_data) = (None, None, None)

    # Data loader only on rank 0 of each model parallel group.
    if mpu.get_model_parallel_rank() == 0:

        (train_data, val_data, test_data) = make_gpt2_dataloaders()
        flags = torch.cuda.LongTensor([int(args.do_train),
                                       int(args.do_valid),
                                       int(args.do_test)])
    else:
        flags = torch.cuda.LongTensor([0, 0, 0])

    # Broadcast num tokens.
    torch.distributed.broadcast(flags,
                                mpu.get_model_parallel_src_rank(),
                                group=mpu.get_model_parallel_group())
    args.do_train = flags[0].item()
    args.do_valid = flags[1].item()
    args.do_test = flags[2].item()

    return train_data, val_data, test_data


if __name__ == "__main__":

    pretrain(get_train_val_test_data, model_provider, forward_step,
             args_defaults={'tokenizer_type': 'GPT2BPETokenizer'})
