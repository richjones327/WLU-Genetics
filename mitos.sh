#!/bin/bash

dir=$(pwd)
sample=$1
sample=$(basename $sample)

echo "## Working on "$sample" ##"
mconda_profile=$(find ~/ -name 'conda.sh' | grep 'etc/profile')
mconda=$(find ~/ -name 'miniconda' | xargs basename)
  
source $mconda_profile

if [ ! -d ~/$mconda/envs/mitos ]; then
    conda create -n mitos "mitos>2" -y -q
fi

mitos=$(find ~/$mconda/envs/mitos -name "runmitos.py")

if [[ "$sample" == *"circ"* ]]; then
    echo "## Sample is circular ##"
    name=$(basename $sample .fasta | sed 's/_circ//')
elif [[ "$sample" == *"linear"* ]]; then
    echo "## Sample is linear ##"
    name=$(basename $sample .fasta | sed 's/_linear//')
fi
    
conda activate mitos

sed -i 's/\*/N/g' $dir/novoplasty/$sample

mkdir -p $dir/mitos/$name

if [ ! -f mitos/$name/"$name"_reorder.fasta ]; then
    echo '## This will take a few minutes ##'
    if [[ "$sample" == *"circ"* ]]; then
        python $mitos -i novoplasty/$sample -c 5 -o $dir/mitos/$name -r $dir/refseq89m
    elif [[ "$sample" == *"linear"* ]]; then    
        python $mitos -i novoplasty/$sample -c 5 -o $dir/mitos/$name -r $dir/refseq89m --linear
    fi
    else
        echo "## Already completed, skipping ##"
fi

if [ -d $dir/mitos/$name/0/ ]; then
    mv $dir/mitos/$name/0/* $dir/mitos/$name/
fi

cd $dir/

curl -L -O https://raw.githubusercontent.com/richjones327/WLU-Genetics/refs/heads/main/gene_order.txt

cd $dir/mitos/$name/

cat result.fas | awk '{if(NR==1) {print $0} else {if($0 ~ /^>/) {print "\n"$0} else {printf $0}}}' > $name.fasta
sed -i -E "s/Contig[0-9]; [0-9]{1,}-[0-9]{1,}; [-+]; /$name |/g" $name.fasta
sed -i 's/rrnL/16S/' $name.fasta
sed -i 's/rrnS/12S/' $name.fasta

> "$name"_reorder.fasta
while IFS= read -r gene; do
    grep --no-group-separator -A 1 "$gene" $name.fasta >> "$name"_reorder.fasta
done < ~/$dir/gene_order.txt

if [ ! -d $dir/mitos/annotated ]; then
    mkdir $dir/mitos/annotated
fi

cat "$name"_reorder.fasta > $dir/mitos/annotated/$name.fasta
