##################################################################
# lookup datasets
##################################################################
dev-cli dataset_description query -g GD-2021-03-09-1-1 -t sequencing_fastq -j |grep gs:
gsutil -m cp gs://augustus-automatically-managed/sequencing_fastq/30-494985145_fastq_v1/GD-2021-03-09-1-1* .

##################################################################
# run cellranger5
##################################################################
time docker run \
-v ${HOME}/Data:/data gcr.io/mbresearchproject/pipeline_cellranger-base-5.0.1:latest \
cellranger vdj \
--id GD-2021-03-09-1-1 \
--reference /data/refdata-cellranger-vdj-GRCh38-alts-ensembl-5.0.0 \
--fastqs /data/GD_fastq/ \
--sample GD-2021-03-09-1-1 \
--inner-enrichment-primers /data/GD_fastq/primers_mix1_2.txt

##################################################################
# run cellranger3.1
##################################################################
time docker run \
-v ${HOME}/Data:/data gcr.io/mbresearchproject/pipeline_cellranger-base:latest \
cellranger vdj \
--id GD-2021-03-09-1-1 \
--reference /data/refdata-cellranger-vdj-GRCh38-alts-ensembl-5.0.0 \
--fastqs /data/GD_fastq/ \
--sample GD-2021-03-09-1-1 \
--inner-enrichment-primers /data/GD_fastq/primers_mix1_2.txt


##################################################################
# run cellranger 3.0.2
##################################################################
docker run -dit \
-v ${HOME}/Data/:/data/ \
gcr.io/mbresearchproject/pipeline_cellranger-base:latest

id=lucid_keldysh
# install cellranger 3.0.2 on the cellranger base docker container
docker exec $id curl -o cellranger-3.0.2.tar.gz \
"https://cf.10xgenomics.com/releases/cell-exp/cellranger-3.0.2.tar.gz?Expires=1627021172&Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9jZi4xMHhnZW5vbWljcy5jb20vcmVsZWFzZXMvY2VsbC1leHAvY2VsbHJhbmdlci0zLjAuMi50YXIuZ3oiLCJDb25kaXRpb24iOnsiRGF0ZUxlc3NUaGFuIjp7IkFXUzpFcG9jaFRpbWUiOjE2MjcwMjExNzJ9fX1dfQ__&Signature=cnSoZN~XZ2AAba1RWVaVun6lbK~qWYAUG-uQqg2mH82W8cLKvx0srNAx8J31zAVoWPLZW8Oo7ABjW6dE9nAfw1nzWEHGgZbBM~DhtUk~Z6FJh2KwRM0eQLR6bBVeR4qkadzW7ZKPTWvxs0INBStJJ9n3-CxA3CGIHNviVtY2xXbisICoCx56wOB62EOjpOwy~R6om76M5dOvjlLaNEdSiGPVLUHSfeNTiNcQgQdzW4DogN2YduQvNb1jsDfu9ytLDz2Ue97lDcD3p3h3F6ClSMMMS2eEGjau-rjql-EKy5XiaJ~mmkxrJ3i-UkzKYcmLzmHVVWfnuOhbTXW20uevIw__&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA"

docker exec $id tar -xzvf cellranger-3.0.2.tar.gz
docker exec $id which cellranger
docker exec $id rm -rf /opt/cellranger/
docker exec $id mv cellranger-3.0.2 /opt/
# --inner-enrichment-primers /data/GD_fastq/primers_mix1_2.txt option doesn't work with cellranger-3.0.2 but does with cellranger-3.1.0 so maybe that's the reason why the behavior changed?
docker exec $id /opt/cellranger-3.0.2/cellranger vdj \
--id GD-2021-03-09-1-1 \
--reference /data/refdata-cellranger-vdj-GRCh38-alts-ensembl-5.0.0 \
--fastqs /data/GD_fastq/ \
--sample GD-2021-03-09-1-1

##################################################################
# run Igblast
##################################################################
# start docker with igblast
docker run -dit \
-v ${HOME}/Code/gamma-delta/:/data/ \
gcr.io/mbresearchproject/pipeline_bcr-alignment-changeo:latest 
# run igblast
HOME='/opt/igblast/ncbi-igblast-1.16.0'
docker exec -w $HOME $id \
AssignGenes.py igblast \
-s /data/results/cellranger5_outs/all_contig.fasta \
-b /opt/igblast/ncbi-igblast-1.16.0 \
--organism human \
--loci tr \
--format blast \
--outdir /data/results/
#process igblast output
docker exec -w $HOME $id \
MakeDb.py igblast \
-i /data/all_contig_igblast.fmt7 \
-s /data/all_contig.fasta \
-r /data/db/ref_fasta/TRAJ.fasta  /data/db/ref_fasta/TRBD.fasta  \
/data/db/ref_fasta/TRDD.fasta  /data/db/ref_fasta/TRDV.fasta  \
/data/db/ref_fasta/TRGV.fasta /data/db/ref_fasta/TRAV.fasta  \
/data/db/ref_fasta/TRBV.fasta  /data/db/ref_fasta/TRDJ.fasta  /data/db/ref_fasta/TRGJ.fasta \
--extended --partial
# download results
docker cp $id:data/all_contig_igblast.fmt7 /home/local/Code/gamma-delta/results
docker cp $id:data/all_contig_igblast_db-pass.tsv /home/local/Code/gamma-delta/results
# extract clonal results from igblast
awk '/All query sequence/{flag=1; next; next} /\# BLAST processed/{flag=0} flag' \
all_contig_igblast.fmt7 > all_contig_igblast.clones.tsv
##################################################################
# run HighV-Quest
##################################################################
# note: this is here for completeness, does not perform as well as igblast so doesn't need to be run
# http://www.imgt.org/HighV-QUEST/home.action
# the relevant output is named vquest_airr.tsv
##################################################################
# run BLASTN against constant region
##################################################################
# more detailed notes https://www.notion.so/chenlingxu/BLAST-against-Constant-Region-7cc62335ef504975bdd21610a15329fd
# download reference from here
# https://www.imgt.org/genedb/resultPage.action?model.gene.id.species=Homo+sapiens&model.molComponent=TR&model.geneTypeLike=constant&model.allele.fcode=functional&model.cloneName=&model.locusLike=any&model.mainLocusLike=any&model.cosLocusLike=any&model.groupLike=any&model.subgroup=-1&model.geneLike=&model.selection=any
# install blastn
# wget https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.12.0+.dmg
# create database
mkdir -p db/blast/
makeblastdb -in TCR_constant.fasta \
-dbtype nucl \
-out db/blast/TCR_constant -hash_index
# run blast
blastn -query results/cellranger5_outs/all_contig.fasta \
-db db/blast/TCR_constant \
-max_target_seqs 1 \
-outfmt 7 > results/all_contig.TCR_constant.tab