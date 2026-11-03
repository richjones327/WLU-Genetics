#!/bin/bash

dir=$(pwd)
sample=$1
#sample=$(basename $sample .fasta)

if [ ! -f gene_order.txt ]; then
    curl -L -O https://raw.githubusercontent.com/richjones327/WLU-Genetics/refs/heads/main/gene_order.txt
fi

source ~/miniconda3/etc/profile.d/conda.sh

conda activate mitos

if [ ! -d ~/miniconda3/envs/mitos ]; then
    conda create -n mitos "mitos>2" -y -q
fi

mitos=$(find ~/miniconda3/envs/mitos -name "runmitos.py")

if [[ "$sample" == *"circ"* ]]; then
    echo "## Sample is circular ##"
    name=$(basename $sample .fasta | sed 's/_circ//')
elif [[ "$sample" == *"linear"* ]]; then
    echo "## Sample is linear ##"
    name=$(basename $sample .fasta | sed 's/_linear//')
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE=(sed -i '')
else
    SED_INPLACE=(sed -i)
fi 

"${SED_INPLACE[@]}" 's/\*/N/g' $dir/novoplasty/$sample

if [ -d $dir/mitos/$name ]; then
    rm -r $dir/mitos/$name
fi

mkdir -p $dir/mitos/$name/

if [ ! -f mitos/$name/"$name"_reorder.fasta ]; then
    echo '## This will take a few minutes ##'
    if [[ "$sample" == *"circ"* ]]; then
        python $mitos -i novoplasty/$sample -c 5 -o $dir/mitos/$name -R $dir/refseq89m/ -r $dir/refseq89m --noplots
    elif [[ "$sample" == *"linear"* ]]; then    
        python $mitos -i novoplasty/$sample -c 5 -o $dir/mitos/$name -r $dir/refseq89m/ -r $dir/refseq89m --noplots --linear
    fi
else
    echo "## Already completed, skipping ##"
fi

if [ -d $dir/mitos/$name/0/ ]; then
    mv $dir/mitos/$name/0/* $dir/mitos/$name/
fi

cd $dir/

cd $dir/mitos/$name/

cat result.fas | awk '{if(NR==1) {print $0} else {if($0 ~ /^>/) {print "\n"$0} else {printf $0}}}' > $name.fasta
"${SED_INPLACE[@]}" -E "s/Contig[0-9]; [0-9]{1,}-[0-9]{1,}; [-+]; /$name |/g" $name.fasta
"${SED_INPLACE[@]}" 's/rrnL/16S/' $name.fasta
"${SED_INPLACE[@]}" 's/rrnS/12S/' $name.fasta

> "$name"_reorder.fasta
for gene in cox1 cox2 trnk trnD atp8 atp6 cox3 trnG nad3 trnA trnR trnN ternS1 trnE trnF nad5 trnH nad4 nad4l trnT trnP nad6 cob trnS2 nad1 trnL2 trnL1 16S trnV 12S OL OH trnI trnQ trnM nad2 trnC trnY; do
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo ">$name |$gene" >> "$name"_reorder.fasta
        grep -A 1 "$gene" $name.fasta | tail -n 1 | sed '/--/d' >> "$name"_reorder.fasta
    else
        echo ">$name |$gene" >> "$name"_reorder.fasta
        grep --no-group-separator -A 1 "$gene" $name.fasta | tail -n 1 >> "$name"_reorder.fasta
    fi
done

if [ ! -d $dir/mitos/annotated ]; then
    mkdir $dir/mitos/annotated
fi

cat "$name"_reorder.fasta > $dir/mitos/annotated/$name.fasta
