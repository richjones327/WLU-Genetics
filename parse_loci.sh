#!/bin/bash

source ~/miniconda3/etc/profile.d/conda.sh

for i in *.fasta; do 
    name=$(basename $i .fasta)
    for gene in cox1 cox2 cox3 nad1 nad2 nad3 nad4 nad4l nad5 nad6 apt8 apt6 cob 16s 12s; do
        count=$(grep -c "$gene" $i)
        if [ "$count" -eq 1 ]; then 
            echo ">$name |$gene" >> $gene.fasta
            grep -A 1 "$gene" $i | tail -n 1 >> $gene.fasta
        fi
    mafft --adjustdirection --auto $gene.fasta > $gene_aligned.fasta
    done
done

conda activate bootleg


