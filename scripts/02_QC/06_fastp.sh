#!/bin/bash
#SBATCH --job-name=fastp
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 8
#SBATCH --mem=20G
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ryan.j.nguyen@uconn.edu
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH --array=[1-12]%4

hostname
date

module load fastp/0.23.2

# Directory with raw FASTQ files
FASTQ_DIR="/home/FCAM/rnguyen/myProject/data/fastq"
# Directory to save cleaned FASTQ
CLEAN_DIR="/home/FCAM/rnguyen/myProject/results/02_qc/clean_fastq"
mkdir -p $CLEAN_DIR

# List of sample IDs
SAMPLES=("SRR21775846" "SRR21775847" "SRR21775848" "SRR21775849" "SRR21775850" "SRR21775851" "SRR21775852" "SRR21775853" "SRR21775854" "SRR21775855" "SRR21775856" "SRR21775857")

# Pick the sample for this array task
SAMPLE=${SAMPLES[$SLURM_ARRAY_TASK_ID]}

echo "Processing $SAMPLE"

fastp \
    -i "$FASTQ_DIR/${SAMPLE}_1.fastq.gz" \
    -I "$FASTQ_DIR/${SAMPLE}_2.fastq.gz" \
    -o "$CLEAN_DIR/${SAMPLE}_1.clean.fastq.gz" \
    -O "$CLEAN_DIR/${SAMPLE}_2.clean.fastq.gz" \
    -q 20 \
    -l 36 \
    -w $SLURM_CPUS_PER_TASK \
    -h "$CLEAN_DIR/${SAMPLE}_fastp.html" \
    -j "$CLEAN_DIR/${SAMPLE}_fastp.json"


