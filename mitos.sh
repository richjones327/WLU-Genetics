#!/bin/bash

dir=$(pwd)
#sample=$(ls novoplasty/* | sed 's/novoplasty\///')
sample=$(ls novoplasty | sed 's/novoplasty\///)

if [ ! -f gene_order.txt ]; then
    curl -L -O https://raw.githubusercontent.com/richjones327/WLU-Genetics/refs/heads/main/gene_order.txt
fi

source ~/miniconda3/etc/profile.d/conda.sh

conda create -n mitos "mitos>2" seqtk -y -q

mitos=$(find ~/miniconda3/envs/mitos -name "runmitos.py")

if [[ "$sample" == *"circ"* ]]; then
    name=$(basename $sample .fasta | sed 's/_circ//')
elif [[ "$sample" == *"linear"* ]]; then
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

conda activate mitos

if [ ! -f mitos/$name/"$name"_reorder.fasta ]; then
    echo '## Running MITOS. This will take a few minutes ##'
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [[ "$sample" == *"circ"* ]]; then
            $mitos -i novoplasty/$sample -c 5 -o $dir/mitos/$name -R $dir/refseq89m/ -r $dir/refseq89m --noplots
        elif [[ "$sample" == *"linear"* ]]; then    
            $mitos -i novoplasty/$sample -c 5 -o $dir/mitos/$name -R $dir/refseq89m/ -r $dir/refseq89m --noplots --linear
        fi
    else
        if [[ "$sample" == *"circ"* ]]; then
            python $mitos -i novoplasty/$sample -c 5 -o $dir/mitos/$name -R $dir/refseq89m/ -r $dir/refseq89m --noplots
        elif [[ "$sample" == *"linear"* ]]; then    
            python $mitos -i novoplasty/$sample -c 5 -o $dir/mitos/$name -R $dir/refseq89m/ -r $dir/refseq89m --noplots --linear
        fi
    fi
fi

echo "## MITOS done. Parsing ##"

if [ -d $dir/mitos/$name/0/ ]; then
    mv $dir/mitos/$name/0/* $dir/mitos/$name/
fi

cd $dir/

cd $dir/mitos/$name/

#cat result.fas | awk '{if(NR==1) {print $0} else {if($0 ~ /^>/) {print "\n"$0} else {printf $0}}}' > $name.fasta
cat result.fas > $name.fasta
"${SED_INPLACE[@]}" -E "s/Contig[0-9]; [0-9]{1,}-[0-9]{1,}; [-+]; //g" $name.fasta
"${SED_INPLACE[@]}" 's/rrnL/16S/' $name.fasta
"${SED_INPLACE[@]}" 's/rrnS/12S/' $name.fasta
"${SED_INPLACE[@]}" -E 's/\(\w+\)//' $name.fasta

> "$name"_reorder.fasta
for gene in cox1 cox2 trnk trnD atp8 atp6 cox3 trnG nad3 trnA trnR trnN ternS1 trnE trnF nad5 trnH nad4 nad4l trnT trnP nad6 cob trnS2 nad1 trnL2 trnL1 16S trnV 12S OL OH trnI trnQ trnM nad2 trnC trnY; do
    echo "$gene" > gene.txt
    count=$(grep -c "$gene" "$name".fasta)
#    if [[ "$OSTYPE" == "darwin"* ]]; then
#        if [[ "$count" -ge 1 ]]; then
#            echo ">$name |$gene" >> "$name"_reorder.fasta
#            grep -A 1 "$gene" $name.fasta | tail -n 1 | sed '/--/d' >> "$name"_reorder.fasta
#            seqtk subseq "$name".fasta gene.txt >> "$name"_reorder.fasta
#        fi
#    else
        if [[ "$count" -ge 1 ]]; then
            seqtk subseq "$name".fasta gene.txt >> "$name"_reorder.fasta
        fi
#    fi
    rm gene.txt
done

if [ ! -d $dir/mitos/annotated ]; then
    mkdir $dir/mitos/annotated
fi

cat "$name"_reorder.fasta | sed "s/>/>$name |/" > $dir/mitos/annotated/$name.fasta
