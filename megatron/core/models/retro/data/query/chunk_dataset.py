# Copyright (c) 2023, NVIDIA CORPORATION.  All rights reserved.

import torch

from megatron.core.datasets.blended_megatron_dataset_builder import BlendedMegatronDatasetBuilder
from megatron.core.datasets.gpt_dataset import GPTDataset
from megatron.core.models.retro.data.db.utils import get_indexed_dataset_infos
from megatron.core.models.retro.data.utils import (
    get_num_chunks_per_sample,
    print_rank_0,
)

from .utils import get_neighbor_dir


class ChunkDataset(torch.utils.data.Dataset):
    '''Pretraining chunk dataset wraps a standard GPT dataset.

    This dataset conceptually divides each sample (e.g., length 2048)
    into chunks (e.g., length 64) and restructures them into a list of
    chunks (e.g., length num_samples * num_chunks_per_sample).
    '''

    def __init__(self, sample_dataset, sample_length, chunk_length):

        super().__init__()

        self.sample_dataset = sample_dataset
        self.chunk_length = chunk_length
        self.n_chunks_per_sample = get_num_chunks_per_sample(sample_length, chunk_length)
        self.n_samples = len(sample_dataset)
        self.n_chunks = self.n_samples * self.n_chunks_per_sample

    def __len__(self):
        return self.n_chunks

    def __getitem__(self, idx):

        # Convert global chunk index to global sample index & local chunk index.
        sample_idx = idx // self.n_chunks_per_sample
        chunk_idx = idx % self.n_chunks_per_sample

        # Extract sample data.
        sample = self.sample_dataset[sample_idx]
        sample_token_ids = sample["text"]
        sample_doc_ids = sample["document_ids"]

        # Chunk start/end token idxs.
        token_start_idx = chunk_idx * self.chunk_length
        token_end_idx = token_start_idx + self.chunk_length
        chunk_token_ids = sample_token_ids[token_start_idx:token_end_idx]

        # Sample.
        return {
            "doc_ids" : sample_doc_ids,
            "text" : chunk_token_ids,
        }


def train_valid_test_datasets_provider(data_config, train_valid_test_num_samples):
    """Build train, valid, and test datasets."""

    print_rank_0('> building train, validation, and test datasets '
                 'for GPT ...')
    
    train_ds, valid_ds, test_ds = BlendedMegatronDatasetBuilder(
        GPTDataset,
        train_valid_test_num_samples,
        data_config,
    ).build()
    print_rank_0("> finished creating pretrained GPT datasets ...")

    return train_ds, valid_ds, test_ds


def get_chunk_dataset_map(project_dir, gpt_datasets, sample_length, chunk_length):
    '''Get train, valid, test chunk datasets.'''

    # Reset iteration.
    # >>>
    # config.iteration = 0
    # config.consumed_train_samples = 0
    # <<<

    # Info dict.
    chunk_dataset_map = {
        key : {
            "dataset" : ChunkDataset(sample_ds, sample_length, chunk_length),
            "neighbor_dir" : get_neighbor_dir(project_dir, key, sample_ds),
            "num_active_chunks" : num_active_samples * get_num_chunks_per_sample(sample_length, chunk_length),
        }
        for key, (sample_ds, num_active_samples) in vars(gpt_datasets).items() if sample_ds
    }

    return chunk_dataset_map