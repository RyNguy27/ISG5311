#!/bin/bash
#SBATCH --job-name=multiqc
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


##Remove warning

export LC_ALL=en_US.utf8
export LANG=en_US.utf8

module load MultiQC/1.9

STATS=../../results/03_align/samtools_stats
QUALIMAP=../../results/03_align/qualimap_reports
OUTDIR=../../results/03_align/multiqc

# run on samtool stats output
multiqc -f -o ${OUTDIR}/samtools_stats ${STATS}

# run on qualimap output
multiqc -f -o ${OUTDIR}/qualimap ${QUALIMAP}
