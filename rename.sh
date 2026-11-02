#!/bin/bash

mkdir 01_eremospina
mkdir 02_lcwgs

rm -r uce-matches/
rm -r aligned/
rm -r unaligned/
rm -r exploded-fastas/

mv contigs 01_eremospina/01_contigs

cd 01_eremospina/01_contigs

mv Eremospina_minamoritaana_CNANSO333.fasta Eremospina_minamoritaana_CNANSO333.fasta
mv Eremospina_minamoritaana_CNANSol189.fasta Eremospina_minamoritaana_CNANSol189.fasta
mv Eremospina_fusca_CIDA107918.fasta Eremospina_fusca_CIDA107918.fasta
mv Eremospina_fusca_CNANSO368.fasta Eremospina_fusca_CNANSO368.fasta
mv Eremospina_azteca_UAAAGS48.fasta Eremospina_azteca_UAAAGS48.fasta
mv Eremospina_azteca_CNANSO405.fasta Eremospina_azteca_CNANSO405.fasta
mv Eremospina_azteca_CNANSO103F.fasta Eremospina_azteca_CNANSO103F.fasta
mv Eremospina_azteca_CNANSO103M.fasta Eremospina_azteca_CNANSO103M.fasta
mv Eremospina_tolteca_CNANSO130.fasta Eremospina_tolteca_CNANSO130.fasta
mv Eremospina_tolteca_UAEH.fasta Eremospina_tolteca_UAEH.fasta
mv Eremospina_tolteca_CNANSol040.fasta Eremospina_tolteca_CNANSol040.fasta
mv Eremospina_tolteca_CNANSO366.fasta Eremospina_tolteca_CNANSO366.fasta
mv Eremospina_tachi_CNANSO383.fasta Eremospina_tachi_CNANSO383.fasta
mv Eremospina_ngiwa_CNANSO343.fasta Eremospina_ngiwa_CNANSO343.fasta
mv Eremospina_mixteca_ZA47523.fasta Eremospina_mixteca_ZA47523.fasta
mv Eremospina_mixteca_CNANSO386.fasta Eremospina_mixteca_CNANSO386.fasta
mv Eremospina_acuitlapanensis_CNANSO397.fasta Eremospina_acuitlapanensis_CNANSO397.fasta
mv Eremospina_acuitlapanensis_CNANSol121.fasta Eremospina_acuitlapanensis_CNANSol121.fasta
mv Eremospina_tolteca_CNANSO331.fasta Eremospina_tolteca_CNANSO331.fasta

cd ../

grep -rlZ "Eremospina_minamoritaana_CNANSO333" ./ | xargs -0 sed -i "s/Eremospina_minamoritaana_CNANSO333/Eremospina_minamoritaana_CNANSO333/g"
grep -rlZ "Eremospina_minamoritaana_CNANSol189" ./ | xargs -0 sed -i "s/Eremospina_minamoritaana_CNANSol189/Eremospina_minamoritaana_CNANSol189/g"
grep -rlZ "Eremospina_fusca_CIDA107918" ./ | xargs -0 sed -i "s/Eremospina_fusca_CIDA107918/Eremospina_fusca_CIDA107918/g"
grep -rlZ "Eremospina_fusca_CNANSO368" ./ | xargs -0 sed -i "s/Eremospina_fusca_CNANSO368/Eremospina_fusca_CNANSO368/g"
grep -rlZ "Eremospina_azteca_UAAAGS48" ./ | xargs -0 sed -i "s/Eremospina_azteca_UAAAGS48/Eremospina_azteca_UAAAGS48/g"
grep -rlZ "Eremospina_azteca_CNANSO405" ./ | xargs -0 sed -i "s/Eremospina_azteca_CNANSO405/Eremospina_azteca_CNANSO405/g"
grep -rlZ "Eremospina_azteca_CNANSO103F" ./ | xargs -0 sed -i "s/Eremospina_azteca_CNANSO103F/Eremospina_azteca_CNANSO103F/g"
grep -rlZ "Eremospina_azteca_CNANSO103M" ./ | xargs -0 sed -i "s/Eremospina_azteca_CNANSO103M/Eremospina_azteca_CNANSO103M/g"
grep -rlZ "Eremospina_tolteca_CNANSO130" ./ | xargs -0 sed -i "s/Eremospina_tolteca_CNANSO130/Eremospina_tolteca_CNANSO130/g"
grep -rlZ "Eremospina_tolteca_UAEH" ./ | xargs -0 sed -i "s/Eremospina_tolteca_UAEH/Eremospina_tolteca_UAEH/g"
grep -rlZ "Eremospina_tolteca_CNANSol040" ./ | xargs -0 sed -i "s/Eremospina_tolteca_CNANSol040/Eremospina_tolteca_CNANSol040/g"
grep -rlZ "Eremospina_tolteca_CNANSO366" ./ | xargs -0 sed -i "s/Eremospina_tolteca_CNANSO366/Eremospina_tolteca_CNANSO366/g"
grep -rlZ "Eremospina_tachi_CNANSO383" ./ | xargs -0 sed -i "s/Eremospina_tachi_CNANSO383/Eremospina_tachi_CNANSO383/g"
grep -rlZ "Eremospina_ngiwa_CNANSO343" ./ | xargs -0 sed -i "s/Eremospina_ngiwa_CNANSO343/Eremospina_ngiwa_CNANSO343/g"
grep -rlZ "Eremospina_mixteca_ZA47523" ./ | xargs -0 sed -i "s/Eremospina_mixteca_ZA47523/Eremospina_mixteca_ZA47523/g"
grep -rlZ "Eremospina_mixteca_CNANSO386" ./ | xargs -0 sed -i "s/Eremospina_mixteca_CNANSO386/Eremospina_mixteca_CNANSO386/g"
grep -rlZ "Eremospina_acuitlapanensis_CNANSO397" ./ | xargs -0 sed -i "s/Eremospina_acuitlapanensis_CNANSO397/Eremospina_acuitlapanensis_CNANSO397/g"
grep -rlZ "Eremospina_acuitlapanensis_CNANSol121" ./ | xargs -0 sed -i "s/Eremospina_acuitlapanensis_CNANSol121/Eremospina_acuitlapanensis_CNANSol121/g"
grep -rlZ "Eremospina_tolteca_CNANSO331" ./ | xargs -0 sed -i "s/Eremospina_tolteca_CNANSO331/Eremospina_tolteca_CNANSO331/g"
