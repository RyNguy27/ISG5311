#!/bin/bash
#SBATCH --job-name=kallisto
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

# load software
module load kallisto/0.46.1

hostname
date

# folder with FASTQ files
FASTQ_DIR="/home/FCAM/rnguyen/myProject/results/02_qc/clean_fastq"
# output folder for Kallisto results
OUT_DIR="/home/FCAM/rnguyen/myProject/genome/kallisto_quant2"
IDX="/home/FCAM/rnguyen/myProject/genome/kallisto_index/Mus_musculus_GRCm39.idx"

mkdir -p $OUT_DIR

#############################################
# Get sample names from SraRunTable.txt
#############################################
# Make sure this file has a column named Run or Run_sra or similar
SRA_TABLE="/home/FCAM/rnguyen/myProject/metadata/SraRunTable.txt"

# Extract sample IDs (SRA Run IDs)
samples=($(awk 'NR>1{print $1}' $SRA_TABLE))

#############################################
# Run Kallisto quant for all samples
#############################################
for s in "${samples[@]}"; do
    echo "Processing sample $s..."
    kallisto quant -i $IDX \
        -o $OUT_DIR/$s \
        -t 8 \
        $FASTQ_DIR/${s}_1.clean.fastq.gz $FASTQ_DIR/${s}_2.clean.fastq.gz
done

date

