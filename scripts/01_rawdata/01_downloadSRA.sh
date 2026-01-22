#!/bin/bash
#SBATCH --job-name=fasterq_dump_xanadu
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 12
#SBATCH --mem=15G
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ryan.j.nguyen@uconn.edu
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err

hostname
date

#stop perl warning
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# load software
module load parallel/20180122
module load sratoolkit/3.0.1

# The data are from this study:
  # https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE156460
  # https://www.ncbi.nlm.nih.gov/bioproject/?term=PRJNA886048https://www.ncbi.nlm.nih.gov/bioproject/?term=PRJNA886048

# Directories
OUTDIR=/home/FCAM/rnguyen/myProject/data/fastq
    mkdir -p ${OUTDIR}
METADATA=/home/FCAM/rnguyen/myProject/metadata/SraRunTable.txt
ACCLIST=/home/FCAM/rnguyen/myProject/metadata/accessionlist.txt

# Extract only strings that look like SRR followed by digits
grep -o 'SRR[0-9]\+' $METADATA > $ACCLIST

# Change were temp files download due to avail space
export TMPDIR=/scratch/rnguyen/tmp

# use parallel to download 2 accessions at a time. 
cat $ACCLIST | parallel --tmpdir ${OUTDIR} --compress -j 2 "fasterq-dump --split-files -t ${OUTDIR}  -O ${OUTDIR} {} && gzip ${OUTDIR}/*fastq"

date
