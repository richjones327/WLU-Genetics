#!/bin/bash

for i in *.fasta; do 
    name=$(basename $i .fasta)
    count=$(grep -c 'cox1' $i)
    if [ "$count" -ge 1 ]; then 
        echo ">$name |cox1" >> cox1.fasta
        grep -A 1 'cox1' $i | tail -n 1 >> cox1.fasta
    fi
done

