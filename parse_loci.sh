#!/bin/bash

source ~/miniconda3/etc/profile.d/conda.sh

for i in *.fasta; do 
    name=$(basename $i .fasta)
    count=$(grep -c 'cox1' $i)
    if [ "$count" -ge 1 ]; then 
        echo ">$name |cox1" >> cox1.fasta
        grep -A 1 'cox1' $i | tail -n 1 >> cox1.fasta
    fi
done

conda activate bootleg

mafft --auto cox1.fasta > aligned_cox1.fasta
