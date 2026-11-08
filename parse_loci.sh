#!/bin/bash

source ~/miniconda3/etc/profile.d/conda.sh

conda activate bootleg

if [ ! -d loci ]; then
    mkdir loci
else
    rm loci/*
fi

for gene in cox1 cox2 cox3 nad1 nad2 nad3 nad4 nad4l nad5 nad6 atp8 atp6 cob 16S 12S; do
    > loci/$gene.fasta  
    for i in *.fasta; do 
        name=$(basename $i .fasta)
        count=$(grep -c "$gene" $i)
        if [[ "$count" ==   1 ]]; then 
            echo ">$name |$gene" >> loci/$gene.fasta
            grep -A 1 "$gene" $i | tail -n 1 >> loci/"$gene".fasta
        fi
    done
done


cd loci

if [ ! -d aligned ]; then
    mkdir aligned
else
    rm aligned/*
fi

ls *.fasta | parallel --bar "mafft --quiet --adjustdirection --auto {} > aligned/{.}.fasta"
