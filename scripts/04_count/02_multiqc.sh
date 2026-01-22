#!/bin/bash
#SBATCH --job-name=multiqcCount
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 4
#SBATCH --mem=5G
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ryan.j.nguyen@uconn.edu
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err

hostname
date

#################################################################
# Aggregate reports using MultiQC
#################################################################

module load MultiQC/1.9

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

COUNTS=../../results/04_counts/counts
OUTDIR=../../results/04_counts/multiqc
mkdir -p $OUTDIR

# run on samtool stats output
multiqc -f -o ${OUTDIR} ${COUNTS}

date
