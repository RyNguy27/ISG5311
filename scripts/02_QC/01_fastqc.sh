#!/bin/bash
#SBATCH --job-name=fastqc
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 10
#SBATCH --mem=60G
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ryan.j.nguyen@uconn.edu
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err

echo `hostname`

#################################################################
# FastQC
#################################################################
module load fastqc/0.12.1
module load parallel/20180122

export LC_ALL=C
export LANG=C

# set input/output directory variables
INDIR=../../data/fastq/
REPORTDIR=../../results/02_qc/fastqc_reports
mkdir -p $REPORTDIR

ACCLIST=../../metadata/accessionlist.txt

# debug check
cat $ACCLIST | parallel -j 10 echo fastqc --outdir $REPORTDIR $INDIR/{}_1.fastq.gz $INDIR/{}_2.fastq.gz

# run fastp in parallel, 10 samples at a time
cat $ACCLIST | parallel -j 10 \
    "fastqc --outdir $REPORTDIR $INDIR/{}_1.fastq.gz $INDIR/{}_2.fastq.gz"
