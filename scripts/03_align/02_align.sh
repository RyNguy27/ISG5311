#!/bin/bash
#SBATCH --job-name=align
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 4
#SBATCH --mem=30G
#SBATCH --partition=xeon
#SBATCH --qos=general
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ryan.j.nguyen@uconn.edu
#SBATCH -o %x_%A_%a.out
#SBATCH -e %x_%A_%a.err
#SBATCH --array=[11-12]%8

hostname
date

# Removes warning

export LC_ALL=C
export LANG=C


#################################################################
# Align reads to genome
#################################################################
module load hisat2/2.2.1
module load samtools/1.16.1
INDIR=../../results/02_qc/trimmed_fastq
OUTDIR=../../results/03_align/alignments
mkdir -p ${OUTDIR}

# this is an array job.
        # one task will be spawned for each sample
        # for each task, we specify the sample as below
        # use the task ID to pull a single line, containing a single accession number from the accession list
        # then construct the file names in the call to hisat2 as below

INDEX=../../genome/hisat2_index/Fhet

ACCLIST=../../metadata/accessionlist.txt

### temp directory
export TMPDIR=/scratch/rnguyen/tmp/${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}
mkdir -p ${TMPDIR}

## Get and announce sample name
SAMPLE=$(sed -n ${SLURM_ARRAY_TASK_ID}p ${ACCLIST})

echo "Aligning Sample: ${SAMPLE}"

# run hisat2
hisat2 -p 4 \
        -x ${INDEX} \
        -1 ${INDIR}/${SAMPLE}_trim_1.fastq.gz \
        -2 ${INDIR}/${SAMPLE}_trim_2.fastq.gz | \
samtools sort -@ 2 -T ${TMPDIR}/${SAMPLE} -o ${OUTDIR}/${SAMPLE}.bam

# index bam files
samtools index ${OUTDIR}/${SAMPLE}.bam

# Clean-up tmpdir
rm -rf ${TMPDIR}
