#!/bin/bash
#SBATCH --job-name=qualimap
#SBATCH --mail-user=ryan.j.nguyen@uconn.edu
#SBATCH --mail-type=ALL
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --mem=40G
#SBATCH --qos=general
#SBATCH --partition=general

hostname
date

# Removes warning

export LC_ALL=C
export LANG=C

##################################
# calculate stats on alignments
##################################
# this time we'll use qualimap

# load software--------------------------------------------------------------------------
module load qualimap/2.2.1
module load parallel/20180122

# input, output directories--------------------------------------------------------------

INDIR=../../results/03_align/alignments
OUTDIR=../../results/03_align/qualimap_reports
mkdir -p $OUTDIR

# gtf annotation is required here
GTF=../../genome/Mus_musculus.GRCm39.115.gtf

# accession list
ACCLIST=../../metadata/accessionlist.txt

# run qualimap in parallel
cat $ACCLIST | \
parallel -j 4 \
    qualimap \
        rnaseq \
        -bam $INDIR/{}.bam \
        -gtf $GTF \
        -outdir $OUTDIR/{} \
        --java-mem-size=8G
