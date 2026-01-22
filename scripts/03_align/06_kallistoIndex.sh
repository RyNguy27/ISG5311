#!/bin/bash
#SBATCH --job-name=kallisto
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 16
#SBATCH --mem=10G
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ryan.j.nguyen@uconn.edu
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err

hostname
date

#################################################################
# Index the Genome for Kallisto
#################################################################

# load software
module load kallisto/0.46.1

# input/output directories
OUTDIR=../../genome/kallisto_index
mkdir -p $OUTDIR

# reference transcriptome FASTA
TRANSCRIPTOME=../../genome/Mus_musculus.GRCm39.cdna.all.fa

# build kallisto index
kallisto index -i $OUTDIR/Mus_musculus_GRCm39.idx $TRANSCRIPTOME

date
