#!/bin/bash

source ~/miniconda3/etc/profile.d/conda.sh

conda activate bootleg

if [ ! -d 01_loci ]; then
    mkdir 01_loci
fi

rm 01_loci/*

for gene in cox1 cox2 cox3 nad1 nad2 nad3 nad4 nad4l nad5 nad6 atp6 cob 16S 12S; do
    > 01_loci/$gene.fasta  
    for i in *.fasta; do 
        name=$(basename $i .fasta)
        count=$(grep -c "$gene" $i)
        if [[ "$count" ==   1 ]]; then 
            echo ">$name" >> 01_loci/$gene.fasta
            grep -A 1 "$gene" $i | tail -n 1 >> 01_loci/"$gene".fasta
        fi
    done
done

if [ ! -d 02_aligned ]; then
    mkdir 02_aligned
fi

for i in 01_loci/*.fasta; do
    locus=$(basename $i .fasta)
    mafft --adjustdirection --auto --quiet --maxiterate 1000 $i > 02_aligned/$locus.fasta
done

if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE=(sed -i '')
else
    SED_INPLACE=(sed -i)
fi

"${SED_INPLACE[@]}" 's/_R_//' 02_aligned/*