#!/bin/bash

source ~/miniconda3/etc/profile.d/conda.sh

export OS=$(echo "$OSTYPE")
export dir=$(pwd)
subdir=$(basename $dir)

user=$(whoami)
echo -e "\n## Hello $user ##"

if [[ "$subdir" != "solifuge_dna" ]]; then
	echo "!! Current directory is not solifuge_dna. Navigate to solifuge_dna first !!"
	exit 1
fi
if [ ! -d contigs ]; then
	echo "!! contigs folder not found, make a folder with the .fasta files named 'contigs' !!"
	exit 1
fi

if [ ! -d ~/miniconda3/envs/bootleg ]; then
	echo "## Hello $user, installing packages LASTZ, MAFFT, and Parallel ##"
	conda create -n bootleg -y -q
	conda activate bootleg
	conda install lastz mafft parallel -y -q
fi

conda activate bootleg
#parallel --citation

if [ ! -d uce-matches ]; then
	mkdir uce-matches
else
	rm uce-matches/*
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE=(sed -i '')
	if [ -f /mnt/c/Users/$user/Downloads/probes.fasta ]; then
		mv /mnt/c/Users/$user/Downloads/probes.fasta ./
	fi
else
    SED_INPLACE=(sed -i)
	if [ -f ~/Downloads/probes.fasta ]; then
		mv ~/Downloads/probes.fasta ./
	fi
fi

if [ ! -f $dir/probes.fasta ]; then
	echo -e "\n!! The probes.fasta fill is missing, make sure to download it before re-running !!\n"
	exit 1
fi

echo -e "\n## Starting LASTZ ##\n"

cd contigs
#total=$(ls *.fasta | wc -l)
#sample_count=1
#for fasta in *.fasta; do
#sample=$(basename $fasta .fasta)
#if [ -f ../uce-matches/"$sample-all.csv" ]; then
#	echo "## Skipping $sample ##"
#else
#	echo "## Running LASTZ on $sample_count out of $total ##"
#$fasta[multiple]
ls *.fasta | sed 's/.fasta//' | parallel --bar "lastz {}.fasta[multiple] \
	../probes.fasta \
	--identity=80 \
	--coverage=80 \
	--matchcount=75 \
	--strand=both \
	--seed=12of19 \
	--transition \
	--nogfextend \
	--nochain \
	--gap=400,30 \
	--xdrop=910 \
	--ydrop=8370 \
	--hspthresh=3000 \
	--gappedthresh=3000 \
	--noentropy \
	--format=general:name2,name1,score,identity,coverage,strand1,strand2 | sed -e 's/\t/,/g' -e 's/_length_/,/g' -e 's/_cov_/,/g' | sed -E 's/(uce-[0-9]{1,})_(p[0-9]{1,})/\1,\2/g' > $dir/uce-matches/{}-all.csv"
#fi
#done

if [ ! -d $dir/exploded-fastas/ ]; then
	mkdir $dir/exploded-fastas/
fi

# Modify output spreadsheet
cd $dir/uce-matches/
echo -e "\n## Parsing & extracting UCE hits ##\n"
extract_sample() {
local SED_INPLACE
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE=(sed -i '')
else
    SED_INPLACE=(sed -i)
fi
local sample="$1"
sample=$(basename "$sample" -all.csv)
"${SED_INPLACE[@]}" "/name2/d" "$sample-all.csv"
if [[ "$OSTYPE" == "darwin"* ]]; then
	"${SED_INPLACE[@]}" '1c\
	Locus,Part,Contig,ContigLength,ContigCov,Score,ID,PctID,Probe_Coverage,PctCov,TargetOrientation,QueryOrientation
	' "$sample-all.csv"
else
	"${SED_INPLACE[@]}" "1c\Locus,Part,Contig,ContigLength,ContigCov,Score,ID,PctID,Probe_Coverage,PctCov,TargetOrientation,QueryOrientation" "$sample-all.csv"
fi
#sed -i '' "1c\Locus,Part,Contig,ContigLength,ContigCov,Score,ID,PctID,Probe_Coverage,PctCov,TargetOrientation,QueryOrientation" "$sample-all.csv"

# Collect matches
locus_matches=$(awk -F, '{print $1}' "$sample-all.csv" | sed -E '/Locus/d' | sort -h | uniq)
contig_matches=$(awk -F, '{print $3}' "$sample-all.csv" | sed -E '/Contig/d' | sort -h | uniq)

echo "Locus,Contig,ContigLength,ContigCov,Score,ID,PctID,Probe_Coverage,PctCov" > "$sample.csv"
echo -e "## Loci removed for matching multiple contigs ##" >> "$sample.txt"
while IFS= read -r locus; do
	count=$(grep "$locus," "$sample-all.csv" | awk -F, '{print $1,$3}' | sort | uniq | wc -l)
	if [[ "$count" -ge "2" ]]; then
		echo "Removed "$locus" for matching "$count" contigs " >> "$sample.txt"
	else
		grep "$locus," "$sample-all.csv" | sort -t, -k7nr | head -n 1 | awk -F, '{print $1,$3,$4,$5,$6,$7,$8,$9,$10,$11}' | sed -E 's/[[:blank:]]/,/g' >> "$sample.csv"
	fi
done <<< "$locus_matches"

echo -e "\n## Contigs removed for matching multiple loci ##" >> $sample.txt
while IFS= read -r contig; do
	count=$(grep "$contig," "$sample-all.csv" | awk -F, '{print $1,$3}' | sort | uniq | wc -l)
	if [[ "$count" -ge "2" ]]; then
		echo "Removed "$contig" for matching "$count" loci" >> "$sample.txt"
		"${SED_INPLACE[@]}" "/$contig,/d" "$sample.csv"
	fi
done <<< "$contig_matches"

# Extract UCE matches to "exploded fasta" #
cat $dir/contigs/$sample.fasta | awk '{if(NR==1) {print $0} else {if($0 ~ /^>/) {print "\n"$0} else {printf $0}}}' > $sample.fasta

good_hits=$(tail -n +2 "$sample.csv" | awk -F, '{print $1}')
> $dir/exploded-fastas/$sample.fasta

#echo "## Extracting UCE loci for "$sample" ##"
while IFS= read -r match; do
	contig=$(grep "$match," "$sample.csv" | head -n 1 | awk -F, '{print $2}')
	echo ">$sample |$match" >> $dir/exploded-fastas/$sample.fasta
	grep -A1 "$contig\_" "$sample.fasta" | sed -E "/$contig/d" >> $dir/exploded-fastas/$sample.fasta
done <<< "$good_hits"

rm $sample.fasta

}

export -f extract_sample

parallel --bar extract_sample ::: *all.csv


cd $dir
if [ ! -d unaligned ]; then
	mkdir unaligned
else
	rm unaligned/*
fi

loci=$(grep -hoE 'uce-[0-9]{1,}' $dir/exploded-fastas/*)

while IFS= read -r locus; do
	grep -h -A1 "$locus$" exploded-fastas/* | awk '$0 != "--"' > unaligned/"$locus.fasta"
done <<< "$loci"

cd unaligned

for fasta in *.fasta; do
	locus_count=$(grep -c '>' $fasta)
	if [ "$locus_count" -le 2 ]; then
		rm $fasta
#		echo "!! Removing $fasta for having too few sequences !!"
	fi
done

if [ ! -d ../aligned ]; then
	mkdir ../aligned
else
	rm ../aligned/*
fi

echo -e "\n## Starting alignments ##\n"
ls *.fasta | parallel --bar "mafft \
		--adjustdirection \
		--maxiterate 1000 \
		--quiet \
		--thread 2 \
		--localpair {} > ../aligned/{}"


"${SED_INPLACE[@]}" 's/_R_//g' $dir/aligned/*

echo -e "\n## All down for now, goodbye $user ##\n"