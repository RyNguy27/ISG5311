#!/bin/bash
#SBATCH --job-name=get_genome
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

# load software
module load samtools/1.16.1


# output directory
GENOMEDIR=../../genome
mkdir -p $GENOMEDIR

# download the genome
wget -P ${GENOMEDIR} https://ftp.ensembl.org/pub/release-115/fasta/mus_musculus/dna/Mus_musculus.GRCm39.dna_sm.toplevel.fa.gz

wget -P ${GENOMEDIR} https://ftp.ensembl.org/pub/release-115/gtf/mus_musculus/Mus_musculus.GRCm39.115.gtf.gz

wget -P ${GENOMEDIR} https://ftp.ensembl.org/pub/release-115/fasta/mus_musculus/cdna/Mus_musculus.GRCm39.cdna.all.fa.gz

# decompress files
gunzip ${GENOMEDIR}/*gz

# generate simple samtools fai indexes 
samtools faidx ${GENOMEDIR}/Mus_musculus.GRCm39.dna_sm.toplevel.fa
samtools faidx ${GENOMEDIR}/Mus_musculus.GRCm39.cdna.all.fa
