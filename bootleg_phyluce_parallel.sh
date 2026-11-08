#!/bin/bash

source ~/miniconda3/etc/profile.d/conda.sh

export OS=$(echo "$OSTYPE")
export dir=$(pwd)

user=$(whoami)
echo -e "\n## Hello $user ##"

if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE=(sed -i '')
else
    SED_INPLACE=(sed -i)
fi

#if ! [[ "$dir" == *solifuge_dna/01_eremospina* ]]; then
#	echo "!! Current directory is not solifuge_dna. Navigate to solifuge_dna first !!"
#	exit 1
#                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         fi

if [ ! -f $dir/probes.fasta ]; then
	curl -L -O https://raw.githubusercontent.com/richjones327/WLU-Genetics/refs/heads/main/probes.fasta
fi

#echo "## Hello $user, installing packages LASTZ, MAFFT, and Parallel ##"
#conda create -n bootleg lastz mafft parallel trimal aliview -y -q
#conda create -n amas amas -y -q
#conda create -n iqtree iqtree figtree -y -q

conda activate bootleg

if [ ! -d 02_uce-matches ]; then
	mkdir 02_uce-matches
fi

if [ ! -d $dir/03_exploded-fastas/ ]; then
	mkdir $dir/03_exploded-fastas/
fi

cd 01_contigs/

echo "## Generating assembly statistics ##"

echo "sample,contig_number,avg_length,median_length,max_length,min_length" > ../contig_stats.csv
contig_statistics() {
    local sample="$1"
	sample=$(basename $1 .fasta)
	contigs_num=$(grep -c '>' $sample.fasta)
    contigs=$(grep '>' $sample.fasta)
	sum=0
	while IFS='_' read -r node number len length cov coverage; do
		sum=$((sum + length))
		echo "$node_$number,$length" >> $sample-list.txt
	done <<< "$contigs"
	average=$((sum / contigs_num))
	max=$(tail -n +2 $sample-list.txt | sort -t, -hk2 | tail -n 1 | awk -F, '{print $2}')
	min=$(tail -n +2 $sample-list.txt | sort -t, -hk2 | head -n 1 | awk -F, '{print $2}')
	fifty=$((contigs_num / 2))
	median=$(tail -n +2 $sample-list.txt | sort -t, -hk2 | tail -n $fifty | head -n 1 | awk -F, '{print $2}')
	rm $sample-list.txt
	echo "$sample,$contigs_num,$average,$median,$max,$min" >> ../contig_stats.csv
}

export -f contig_statistics

parallel --bar contig_statistics ::: *.fasta

echo -e "\n## Matching and extracting UCE loci ##\n"

match_probes() {
local sample="$1"
sample=$(basename $1 .fasta)
if [ ! -f $dir/03_exploded-fastas/$sample.fasta ]; then
lastz $sample.fasta[multiple] \
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
	--format=general:name2,name1,score,identity,coverage,strand1,strand2 | sed -e 's/\t/,/g' -e 's/_length_/,/g' -e 's/_cov_/,/g' | sed -E 's/(uce-[0-9]{1,})_(p[0-9]{1,})/\1,\2/g' > $dir/02_uce-matches/$sample-all.csv

local SED_INPLACE
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE=(sed -i '')
else
    SED_INPLACE=(sed -i)
fi

"${SED_INPLACE[@]}" "/name2/d" $dir/02_uce-matches/"$sample-all.csv"
if [[ "$OSTYPE" == "darwin"* ]]; then
	"${SED_INPLACE[@]}" '1c\
	Locus,Part,Contig,ContigLength,ContigCov,Score,ID,PctID,Probe_Coverage,PctCov,TargetOrientation,QueryOrientation
	' $dir/02_uce-matches/"$sample-all.csv"
else
	"${SED_INPLACE[@]}" "1c\Locus,Part,Contig,ContigLength,ContigCov,Score,ID,PctID,Probe_Coverage,PctCov,TargetOrientation,QueryOrientation" $dir/02_uce-matches/"$sample-all.csv"
fi

# Collect matches
locus_matches=$(awk -F, '{print $1}' $dir/02_uce-matches//"$sample-all.csv" | sed -E '/Locus/d' | sort -h | uniq)
contig_matches=$(awk -F, '{print $3}' $dir/02_uce-matches/"$sample-all.csv" | sed -E '/Contig/d' | sort -h | uniq)

echo "Locus,Contig,ContigLength,ContigCov,Score,ID,PctID,Probe_Coverage,PctCov" > $dir/02_uce-matches/"$sample.csv"
echo -e "## Loci removed for matching multiple contigs ##" >> $dir/02_uce-matches/"$sample.txt"
while IFS= read -r locus; do
	count=$(grep "$locus," $dir/02_uce-matches/"$sample-all.csv" | awk -F, '{print $1,$3}' | sort | uniq | wc -l)
	if [[ "$count" -ge "2" ]]; then
		echo "Removed "$locus" for matching "$count" contigs " >> $dir/02_uce-matches/"$sample.txt"
	else
		grep "$locus," $dir/02_uce-matches/"$sample-all.csv" | sort -t, -k7nr | head -n 1 | awk -F, '{print $1,$3,$4,$5,$6,$7,$8,$9,$10,$11}' | sed -E 's/[[:blank:]]/,/g' >> $dir/02_uce-matches/"$sample.csv"
	fi
done <<< "$locus_matches"

echo -e "\n## Contigs removed for matching multiple loci ##" >> $dir/02_uce-matches/$sample.txt
while IFS= read -r contig; do
	count=$(grep "$contig," $dir/02_uce-matches/"$sample-all.csv" | awk -F, '{print $1,$3}' | sort | uniq | wc -l)
	if [[ "$count" -ge "2" ]]; then
		echo "Removed "$contig" for matching "$count" loci" >> $dir/02_uce-matches/"$sample.txt"
		"${SED_INPLACE[@]}" "/$contig,/d" $dir/02_uce-matches/"$sample.csv"
	fi
done <<< "$contig_matches"

# Extract UCE matches to "exploded fasta" #
cat $dir/01_contigs/$sample.fasta | awk '{if(NR==1) {print $0} else {if($0 ~ /^>/) {print "\n"$0} else {printf $0}}}' > $dir/02_uce-matches/$sample.fasta

good_hits=$(tail -n +2 $dir/02_uce-matches/"$sample.csv" | awk -F, '{print $1}')
> $dir/03_exploded-fastas/$sample.fasta

while IFS= read -r match; do
	contig=$(grep "$match," $dir/02_uce-matches/"$sample.csv" | head -n 1 | awk -F, '{print $2}')
	echo ">$sample |$match" >> $dir/03_exploded-fastas/$sample.fasta
	grep -A1 "$contig\_" $dir/02_uce-matches/"$sample.fasta" | sed -E "/$contig/d" >> $dir/03_exploded-fastas/$sample.fasta
done <<< "$good_hits"

rm $dir/02_uce-matches/$sample.fasta
fi
}

export -f match_probes

parallel --bar match_probes ::: *.fasta

echo "## Parsing UCE loci ##"
cd $dir

if [ -d 04_loci ]; then
	rm -r 04_loci
fi

mkdir 04_loci

loci=$(grep -hoE 'uce-[0-9]{1,}' $dir/03_exploded-fastas/*)

while IFS= read -r locus; do
	grep -h -A1 "$locus$" 03_exploded-fastas/* | awk '$0 != "--"' > 04_loci/"$locus.fasta"
done <<< "$loci"

echo "## Generating statistics ##"
echo "sample,uce_loci,avg_length,median_length,max_length,min_length,uces_removed,contigs_removed"> uce_stats.csv

uce_statistics() {
    local sample="$1"
	sample=$(basename $1 .fasta)
	uce_loci=$(grep -c '>' 03_exploded-fastas/$sample.fasta)
	contigs_removed=$(grep -c "Removed NODE" 02_uce-matches/$sample.txt)
	uces_removed=$(grep -c 'Removed uce' 02_uce-matches/$sample.txt)
	hits=$(grep -o -E "uce-[0-9]+" 03_exploded-fastas/$sample.fasta)
	sum=0
	while IFS= read -r loci; do
		length=$(grep -E -A1 "$loci$" 03_exploded-fastas/"$sample".fasta | tail -n 1 | wc -m)
		sum=$((sum + length))
		echo "$loci,$length" >> $sample-list.txt
	done <<< "$hits"
	average=$((sum / uce_loci))
	max=$(tail -n +2 $sample-list.txt | sort -t, -hk2 | tail -n 1 | awk -F, '{print $2}')
	min=$(tail -n +2 $sample-list.txt | sort -t, -hk2 | head -n 1 | awk -F, '{print $2}')
	fifty=$((uce_loci / 2))
	median=$(tail -n +2 $sample-list.txt | sort -t, -hk2 | tail -n $fifty | head -n 1 | awk -F, '{print $2}')
	rm $sample-list.txt
	echo "$sample,$uce_loci,$average,$median,$max,$min,$uces_removed,$contigs_removed" >> uce_stats.csv
}

export -f statistics

parallel --bar uce_statistics ::: 03_exploded-fastas/*

cd 04_loci

for fasta in *.fasta; do
	locus_count=$(grep -c '>' $fasta)
	if [ "$locus_count" -le 2 ]; then
		rm $fasta
#		echo "!! Removing $fasta for having too few sequences !!"
	fi
done

mkdir 01_aligned
mkdir 02_trimal
mkdir 03_75p_occupancy
echo -e "\n## Aligning and trimming alignments ##\n"

align_trim() {
local align="$1"
align=$(basename $align .fasta)
mafft \
	--adjustdirection \
	--maxiterate 1000 \
	--quiet \
	--thread 6 \
	--localpair $align.fasta > 01_aligned/$align.fasta

local SED_INPLACE
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE=(sed -i '')
else
    SED_INPLACE=(sed -i)
fi
"${SED_INPLACE[@]}" 's/_R_//g' 01_aligned/$align.fasta

trimal -in 01_aligned/$align.fasta \
		-out 02_trimal/$align.fasta \
		-fasta \
		-gt 0.8
}

export -f align_trim

parallel --bar -j 2 align_trim ::: *.fasta

echo "## Creating 75% occupancy matrices ##"

cd 02_trimal

for i in *.fasta; do
	grep '>' $i >> list.txt
done
taxa=$(sort list.txt | uniq | wc -l)
rm list.txt

threshold=$((taxa * 75/100))
for i in *.fasta; do
	count=$(grep -c '>' $i)
	if [[ "$count" -ge "$threshold" ]]; then
		cp $i ../03_75p_occupancy/
	fi
done

echo "## Concatenating ##"
cd ../03_75p_occupancy

conda activate amas

rm $dir/concatenated.fasta
rm $dir/partitions.nex

AMAS.py concat -i *.fasta -d dna -f fasta -u fasta -p $dir/partitions.txt -t $dir/concatenated.fasta

cd $dir

echo "begin sets;" > partitions.nex
cat partitions.txt | sed -E 's/p[0-9]{1,}\_/DNA, /g' >> partitions.nex
echo "end;" >> partitions.nex
rm partitions.txt
echo -e "\n## All done for now, goodbye $user ##\n"
