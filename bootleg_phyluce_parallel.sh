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

if ! [[ "$dir" == *solifuge_dna/01_eremospina* ]]; then
	echo "!! Current directory is not solifuge_dna. Navigate to solifuge_dna first !!"
	exit 1
fi

if [ ! -f $dir/probes.fasta ]; then
	curl -L -O https://raw.githubusercontent.com/richjones327/WLU-Genetics/refs/heads/main/probes.fasta
fi

echo "## Hello $user, installing packages LASTZ, MAFFT, and Parallel ##"
conda create -n bootleg lastz mafft parallel trimal aliview -y -q
conda create -n amas amas -y -q
conda create -n iqtree iqtree figtree -y -q

conda activate bootleg

if [ ! -d 02_uce-matches ]; then
	mkdir 02_uce-matches
else
	rm 02_uce-matches/*
fi

echo -e "\n## Starting LASTZ ##\n"

cd 01_contigs

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
	--format=general:name2,name1,score,identity,coverage,strand1,strand2 | sed -e 's/\t/,/g' -e 's/_length_/,/g' -e 's/_cov_/,/g' | sed -E 's/(uce-[0-9]{1,})_(p[0-9]{1,})/\1,\2/g' > $dir/02_uce-matches/{}-all.csv"

if [ ! -d $dir/03_exploded-fastas/ ]; then
	mkdir $dir/03_exploded-fastas/
fi

# Modify output spreadsheet
cd $dir/02_uce-matches/
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
cat $dir/01_contigs/$sample.fasta | awk '{if(NR==1) {print $0} else {if($0 ~ /^>/) {print "\n"$0} else {printf $0}}}' > $sample.fasta

good_hits=$(tail -n +2 "$sample.csv" | awk -F, '{print $1}')
> $dir/03_exploded-fastas/$sample.fasta

#echo "## Extracting UCE loci for "$sample" ##"
while IFS= read -r match; do
	contig=$(grep "$match," "$sample.csv" | head -n 1 | awk -F, '{print $2}')
	echo ">$sample |$match" >> $dir/03_exploded-fastas/$sample.fasta
	grep -A1 "$contig\_" "$sample.fasta" | sed -E "/$contig/d" >> $dir/03_exploded-fastas/$sample.fasta
done <<< "$good_hits"

rm $sample.fasta

}

export -f extract_sample

parallel --bar extract_sample ::: *all.csv

echo -e "\n## Sorting loci ##"

cd $dir
if [ -d 04_loci ]; then
	rm -r 04_loci
fi

mkdir 04_loci

loci=$(grep -hoE 'uce-[0-9]{1,}' $dir/03_exploded-fastas/*)

while IFS= read -r locus; do
	grep -h -A1 "$locus$" 03_exploded-fastas/* | awk '$0 != "--"' > 04_loci/"$locus.fasta"
done <<< "$loci"

cd 04_loci

for fasta in *.fasta; do
	locus_count=$(grep -c '>' $fasta)
	if [ "$locus_count" -le 2 ]; then
		rm $fasta
#		echo "!! Removing $fasta for having too few sequences !!"
	fi
done

if [ -d 01_aligned ]; then
	rm -r 01_aligned
fi

mkdir 01_aligned/

echo -e "\n## Starting alignments ##\n"
ls *.fasta | parallel --bar "mafft \
		--adjustdirection \
		--maxiterate 1000 \
		--quiet \
		--thread 2 \
		--localpair {} > 01_aligned/{}"


"${SED_INPLACE[@]}" 's/_R_//g' 01_aligned/*

echo "## Trimming Alignments ##"

mkdir 02_trimal
cd 01_aligned/
for align in *.fasta; do
	locus=$(basename $align .fasta)
	trimal -in $align \
		-out ../02_trimal/$locus.fasta \
		-fasta \
		-gt 0.8
done

echo "## Creating 75% occupancy matrices ##"

cd ../02_trimal/
mkdir ../03_75p_occupancy

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

AMAS.py concat -i *.fasta -d dna -f fasta -u fasta -p $dir/partitions.txt -t $dir/concatenated.fasta

cd $dir

echo "begin sets;" > partitions.nex
cat partitions.txt | sed -E 's/p[0-9]{1,}\_//g' >> partitions.nex
echo "end;" >> partitions.nex
echo -e "\n## All done for now, goodbye $user ##\n"
