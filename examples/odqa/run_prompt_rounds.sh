
#!/bin/bash
gpu='5'


for i in {1..1..1} 
    do
        echo ${i}
        nohup bash examples/odqa/run_prompt.sh rnd${i} ${gpu}
        eval wc /gpfs/fs1/projects/gpu_adlr/datasets/dasu/prompting/predicted/TQA/357m/output_answer_generations_k10_357m_gc_multisetdpr_queryctx_p0.9_10000_rnd${i}_withprob.txt
        sleep 10
    done

# list='4 49'
# list='24 39'
# list='61 22'
# list='32'
# list='18 15'
# list='33'

# for i in ${list}
#     do
#         bash examples/odqa/run_prompt.sh $RANDOM rnd${i} ${gpu}
#         sleep 10
#     done