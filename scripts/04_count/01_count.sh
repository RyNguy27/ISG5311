#!/bin/bash
#SBATCH --job-name=htseq_count
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 6
#SBATCH --mem=60G
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ryan.j.nguyen@uconn.edu
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH --array=[1-12]%6

echo `hostname`
date

#################################################################
# Generate Counts
#################################################################
module purge
module load subread/2.0.3


INDIR=/home/FCAM/rnguyen/myProject/results/03_align/alignments
OUTDIR=/home/FCAM/rnguyen/myProject/results/04_counts/counts
mkdir -p $OUTDIR

# accession list
ACCLIST=/home/FCAM/rnguyen/myProject/metadata/accessionlist.txt

# gtf formatted annotation file
GTF=/home/FCAM/rnguyen/myProject/genome/Mus_musculus.GRCm39.115.gtf

# Sample for Array Task
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${ACCLIST}")
echo "Processing sample: $SAMPLE (TASK ID: ${SLURM_ARRAY_TASK_ID})"

COUNT_FILE="${OUTDIR}/${SAMPLE}.counts"
OUTTMP="${OUTDIR}/${SAMPLE}_tmp.counts"
BAM="${INDIR}/${SAMPLE}.bam"

# Skip files already done
if [ -f "$COUNT_FILE" ]; then
    echo "Skipping $SAMPLE --- already counted"
    exit 0
fi

# run featureCounts on each sample, up to 5 threads
    featureCounts -a "$GTF" -o "$OUTTMP" -T 5 -s 0 -p -t exon -g gene_id -Q 10 "${BAM}"

# Convert count
awk '$1 !~ /^#/ {print $1 "\t" $NF}' "$OUTTMP" > "$COUNT_FILE"
rm -f $OUTTMP

echo "FINISHED $SAMPLE"
date
