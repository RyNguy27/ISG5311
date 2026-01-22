library(Biostrings)
library(rtracklayer)
library(tximport)
library(DESeq2)
library(tibble)
library(dplyr)


# Load cDNA FASTA used for Kallisto

cdna <- readDNAStringSet("/Users/rines/OneDrive/Desktop/UCONN ISG COURSE/myProject/genome/Mus_musculus.GRCm39.cdna.all.fa")
tx_ids <- sub(" .*", "", names(cdna))  # remove description after first space


# Load GTF

gtf <- import("/Users/rines/OneDrive/Desktop/UCONN ISG COURSE/myProject/genome/Mus_musculus.GRCm39.115.gtf")


# Build tx2gene mapping

tx2gene <- data.frame(
  transcript_id = sub(" .*", "", names(cdna)),
  gene_id = sub("\\..*", "", sub(" .*", "", names(cdna)))  # often works for Ensembl headers
)

# Remove transcript versions to match Kallisto output
tx2gene$transcript_id <- sub("\\..*$", "", tx2gene$transcript_id)


# Prepare Kallisto files

files <- list.files("/Users/rines/OneDrive/Desktop/UCONN ISG COURSE/myProject/kallisto_quant2", 
                    pattern = "abundance\\.h5", 
                    recursive = TRUE, 
                    full.names = TRUE)


# Run tximport

txi <- tximport(
  files,
  type = "kallisto",
  tx2gene = tx2gene,
  countsFromAbundance = "lengthScaledTPM",
  ignoreTxVersion = TRUE
)

# Quick checks
sum(!rownames(txi$abundance) %in% tx2gene$transcript_id)  # should be 0 or very small
summary(rowSums(txi$counts != 0))  # how many genes have counts


# Run DESeq2

ddskallisto <- DESeqDataSetFromTximport(
  txi,
  colData = sampleTable,  # your metadata table
  design = ~ dose     # or your experimental design
)

#filter very low counts
keep <- rowSums(counts(ddskallisto)) > 1
ddskallisto <- ddskallisto[keep,]

ddskallisto <- DESeq(ddskallisto)

# Extract results
reskallisto <- results(ddskallisto, alpha = 0.05) 
summary(reskallisto)

# Remove NAs first
res_filt <- reskallisto[!is.na(reskallisto$padj), ]

# Order by adjusted p-value (ascending)
res_ordered <- res_filt[order(res_filt$padj), ]
 
# View top 10
head(res_ordered, 10)

