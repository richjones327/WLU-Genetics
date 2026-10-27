#!/bin/bash


source ~/miniconda/etc/profile.d/conda.sh

dir=$(pwd)

mkdir aligned/trimmed
echo -e "## Trimming alignments ##\n"

cd aligned

if [ -d trimal ]; then
	rm -r trimal/
fi

for n in *; do
	locus=$(basename $n .fasta)
	trimal -in $n -out trimal/$locus.fasta -gt 0.2 -fasta
done

if [[ $? -ne 0 ]]; then
	echo -e "!! Trimming failed, aborting !!\n"
	mv $dir/running-trimal.$SLURM_JOB_ID.out $dir/ERROR.trimal."$id"id-"$cov"cov-"$filter".$SLURM_JOB_ID.out
	exit 1
fi






