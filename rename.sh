#!/bin/bash

mkdir 01_eremospina
mkdir 02_lcwgs

rm -r uce-matches/
rm -r aligned/
rm -r unaligned/
rm -r exploded-fastas/
rm SRR*

mv contigs 01_eremospina/01_contigs

cd 01_eremospina/01_contigs

mv SRR36156291.fasta Eremospina_minamoritaana_CNANSO333.fasta
mv SRR36156292.fasta Eremospina_minamoritaana_CNANSol189.fasta
mv SRR36156293.fasta Eremospina_fusca_CIDA107918.fasta
mv SRR36156294.fasta Eremospina_fusca_CNANSO368.fasta
mv SRR36156295.fasta Eremospina_azteca_UAAAGS48.fasta
mv SRR36156296.fasta Eremospina_azteca_CNANSO405.fasta
mv SRR36156297.fasta Eremospina_azteca_CNANSO103F.fasta
mv SRR36156298.fasta Eremospina_azteca_CNANSO103M.fasta
mv SRR36156300.fasta Eremospina_tolteca_CNANSO130.fasta
mv SRR36156301.fasta Eremospina_tolteca_UAEH.fasta
mv SRR36156302.fasta Eremospina_tolteca_CNANSol040.fasta
mv SRR36156303.fasta Eremospina_tolteca_CNANSO366.fasta
mv SRR36156304.fasta Eremospina_tachi_CNANSO383.fasta
mv SRR36156305.fasta Eremospina_ngiwa_CNANSO343.fasta
mv SRR36156306.fasta Eremospina_mixteca_ZA47523.fasta
mv SRR36156307.fasta Eremospina_mixteca_CNANSO386.fasta
mv SRR36156308.fasta Eremospina_acuitlapanensis_CNANSO397.fasta
mv SRR36156309.fasta Eremospina_acuitlapanensis_CNANSol121.fasta
mv SRR36602794.fasta Eremospina_tolteca_CNANSO331.fasta
