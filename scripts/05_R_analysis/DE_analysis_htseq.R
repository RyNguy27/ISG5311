# load packages
library(tidyverse)
library(DESeq2)
library(ggplot2)
library(ggrepel)
library(pheatmap)

# read in and manage metadatas
meta <- read.delim(
  "/Users/rines/OneDrive/Desktop/UCONN ISG COURSE/myProject/metadata/SraRunTable.txt",
  header = TRUE,
  check.names = FALSE,
  stringsAsFactors = FALSE
)

# --- 2. Create dose column ---
meta <- meta %>%
  mutate(
    dose = case_when(
      treatment == "Saline solution" ~ "control",
      treatment == "Baclofen" ~ "exposed"
    ),
    dose = factor(dose)
  ) %>%
  select(Run, `Sample Name`, dose)

# --- 3. List count files ---
directory <- "/Users/rines/OneDrive/Desktop/UCONN ISG COURSE/myProject/results/04_counts/counts"
sampleFiles <- list.files(directory, pattern = "\\.counts$", full.names = FALSE)

# strip extension and check alignment
fileNames <- str_remove(sampleFiles, "\\.counts$")
all(fileNames == meta$Run)

sampleTable <- data.frame(
  sampleName = meta$Run,
  fileName = sampleFiles,
  dose = meta$dose
)

# write out sampleTable
sampleTable

# read the data in:
ddsHTSeq <- DESeqDataSetFromHTSeqCount(
  sampleTable = sampleTable,
  directory = directory,
  design = ~ dose,
)


# read table, transpose it so samples are rows
sn <- read.table("/Users/rines/OneDrive/Desktop/UCONN ISG COURSE/myProject/results/03_align/samtools_stats/SN.txt", header=TRUE, sep="\t") %>% t()
rownames(sn) <- str_remove(rownames(sn), ".*align.")
colnames(sn)  <- str_remove_all(colnames(sn), "[:()%]") %>% str_remove(" $") %>% str_replace_all(" ","_")
sn <- data.frame(sampleID=rownames(sn), sn)

sn <- left_join(sampleTable, sn, join_by(sampleName == sampleID))

# a boxplot of total number of sequences as a function of experimental categories
ggplot(sn, aes(x = dose, y = raw_total_sequences)) + 
  geom_boxplot(outlier.shape = NA, fill = c("lightblue", "salmon")) +  # optional colors
  geom_jitter() +   # add jittered points
  xlab("Dose") +
  ylab("Total Sequences") +
  theme_minimal()

# figure out which sample it is. 
arrange(sn, raw_total_sequences)[,1:4] %>% head(12)

# Error Rate Plot
ggplot(sn,aes(x=dose, y=error_rate)) + 
  geom_boxplot(outlier.shape = NA) + 
  geom_jitter() + 
  xlab("Dose") +
  ylab("Error Rate")

#Proper Pairing Rate
sn %>% 
  mutate(properly_paired_percent = reads_properly_paired / raw_total_sequences) %>%
  ggplot(aes(x=dose, y=properly_paired_percent)) + 
  geom_boxplot(outlier.shape = NA) + 
  geom_jitter() + 
  xlab("Dose") +
  ylab("Properly_Paired_Percent")


rawcounts <- counts(ddsHTSeq)

rowSums(rawcounts) %>%
  quantile(., prob=c(0, 0.01, 0.05, 0.5, 0.95, 0.99, 1))

#Raw Count Graph
data.frame(sumcounts=rowSums(rawcounts)) %>%
  ggplot(aes(x=sumcounts)) + 
  geom_histogram()

#Log10-scaled counts graph
rowSums(rawcounts) %>%
  log(.,10) %>%
  data.frame(logcounts=.) %>%
  ggplot(aes(x=logcounts)) + 
  geom_histogram(binwidth=0.05)

#Log10-scaled with pseudo-count
rowSums(rawcounts + 1) %>%
  log(.,10) %>%
  data.frame(logcounts=.) %>%
  ggplot(aes(x=logcounts)) + 
  geom_histogram(binwidth=0.05)

#Number of Samples with zero counts by gene
rowSums(rawcounts == 0) %>%
  data.frame(zerocounts=.) %>%
  ggplot(aes(x=zerocounts)) +
  geom_histogram(binwidth=1)

##keep genes present in at least 5 samples (fewer than 15 zero counts) and with more than 20 fragments mapping across all samples
keep <- rowSums(rawcounts == 0) < 15 & rowSums(rawcounts) > 20
sum(keep)
ddsHTSeq <- ddsHTSeq[keep,]

# calculate geometric mean "reference" transcriptome profile
gmeans <- apply(rawcounts,MAR=1,FUN=prod)^(1/19)
# calculate a per-sample size factor
sfactors <- apply(rawcounts/gmeans, MAR=2, FUN=median, na.rm=TRUE)

# estimate the size factors
ddsHTSeq <- estimateSizeFactors(ddsHTSeq)

# extract factors
deseqSizeFactors <- sizeFactors(ddsHTSeq)
# plot
plot(x=deseqSizeFactors, y=sfactors)
abline(0,1) 

# fit and summarize linear model
lm(sfactors ~ deseqSizeFactors) %>% summary()

normcounts <- counts(ddsHTSeq, normalized=TRUE)

#Rescaling
vsd <- vst(ddsHTSeq)

#Normal counts vs VST Counts
plot(normcounts, assay(vsd))
#Log2 Normalized counts vs VST counts
plot(log(normcounts,2), assay(vsd))

#PCA Plot
pcaData <- plotPCA(vsd, intgroup="dose", returnData=TRUE)
pcaData$dose <- factor(pcaData$dose, levels = c("control", "exposed"))

ggplot(pcaData, aes(x=PC1, y=PC2, color=dose)) +
  geom_point(size=3) +
  scale_color_manual(values=c("control"="blue", "exposed"="red")) +
  xlab(paste0("PC1: ", round(attr(pcaData, "percentVar")[1]*100, 2), "% variance")) +
  ylab(paste0("PC2: ", round(attr(pcaData, "percentVar")[2]*100, 2), "% variance")) +
  geom_label_repel(aes(label=name))


#Heatmap
# create a metadata data frame to add to the heatmap
df <- data.frame(colData(ddsHTSeq)[,c("dose")])
rownames(df) <- colnames(ddsHTSeq)
colnames(df) <- c("dose")

# find genes with highest variance in expression
rv <- assay(vsd) %>% apply(., MAR=1, FUN=var)
genes50 <- order(rv, decreasing=TRUE)[1:50]

# make the heatmap
pheatmap(
  assay(vsd)[genes50,], 
  cluster_rows=TRUE, 
  show_rownames=TRUE,
  cluster_cols=TRUE,
  annotation_col=df
)

# order samples by dose
sampleOrder <- order(df$dose)
df_ordered <- df[sampleOrder, , drop = FALSE]
expr_ordered <- assay(vsd)[genes50, sampleOrder]

# make the heatmap
pheatmap(
  expr_ordered, 
  cluster_rows = TRUE, 
  cluster_cols = FALSE,    # keeps control/exposed order
  show_rownames = TRUE,
  annotation_col = df_ordered
)

#########################################################################

dds <- DESeq(ddsHTSeq)
res <- results(dds, contrast=c("dose","exposed","control"), alpha = 0.05)
summary(res)

counts(dds)[2,1]
mcols(dds,use.names=TRUE)$dispersion[2]
# draw 10000 random deviates
simvals <- rnbinom(mu=17, size=1/0.1914589, n=10000)
# get quantiles
  quantile(simvals, prob=c(0.025,0.975))
# make a histogram using base R
hist(simvals, breaks=100)

attr(dds, "modelMatrix")
params <- colnames(attr(dds, "modelMatrix"))
mcols(dds)[1:10,params]

params <- colnames(attr(dds, "modelMatrix"))
xr <- unlist(attr(dds, "modelMatrix")[5,])
br <- unlist(mcols(dds)[2,params])
sum( xr * br )

log(counts(dds, normalized=TRUE)[2,5], 2)

gene <- "ENSMUSG00000100764" #enter in a gene to look at it sample by sample
data.frame(
  predicted=attr(dds, "modelMatrix") %*% unlist(mcols(dds)[gene,params]),
  observed=log(counts(dds, normalized=TRUE)[gene,],2)
)

model.matrix(~ dose, sampleTable)

# create a second data object to demonstrate
ddsHTSeq2 <- ddsHTSeq

# add the new aggregate factor and print it
ddsHTSeq2$fac <- factor(paste(ddsHTSeq2$population, ddsHTSeq2$dose, sep="."))
ddsHTSeq2$fac

# update the design
design(ddsHTSeq2) <- ~ fac

# fit the model
dds2 <- DESeq(ddsHTSeq2)

# print the model matrix
attr(dds2, "modelMatrix")

#Plot dispersion parameter estimate chart
plotDispEsts(dds)

#Extracting Results
res <- results(dds, name="dose_exposed_vs_control")
head(res) # print the first 6 lines from the table

resultsNames(dds)
summary(res)

res <- results(dds, name="dose_exposed_vs_control")

##Fold shrinkage
res_shrink <- lfcShrink(dds,type="ashr",coef="dose_exposed_vs_control")

data.frame(l2fc=res$log2FoldChange, l2fc_shrink=res_shrink$log2FoldChange, padj=res$padj) %>%
  filter(l2fc > -5 & l2fc < 5 & l2fc_shrink > -5 & l2fc_shrink < 5) %>%
  ggplot(aes(x=l2fc, y=l2fc_shrink,color=padj < 0.1)) +
  geom_point(size=.25) + 
  geom_abline(intercept=0,slope=1, color="gray")

res_ranked <- as.data.frame(res_shrink) %>%
  filter(padj < 0.1) %>%
  arrange(-abs(log2FoldChange))
head(res_ranked, n=10)

##Plot counts per gene chart
plotCounts(dds, "ENSMUSG00000100764", intgroup=c("dose"))

##ggplot of counts per gene 
data.frame(sampleTable,count=counts(dds,normalized=TRUE)["ENSMUSG00000100764",]) %>%
       ggplot(aes(x=dose, y=log(count,10))) + 
       geom_boxplot(outlier.shape = NA) + 
       geom_jitter()

# dose effect 
dose <- results(dds, contrast=list(c("dose_exposed_vs_control")))
dose_shrink <- lfcShrink(dds, type="ashr", coef="dose_exposed_vs_control")

# pull the top 50 genes by shrunken log2 fold change
top50 <- dose_shrink %>% 
  data.frame() %>%
  filter(padj < 0.1) %>%
  arrange(-abs(log2FoldChange)) %>%
  rownames %>%
  head(n=50)

# make the heatmap
pheatmap(
  assay(vsd)[top50,], 
  cluster_rows=TRUE, 
  show_rownames=TRUE,
  cluster_cols=TRUE,
  annotation_col=df
)

#Spearman correlation clustering
pheatmap(
  assay(vsd)[top50,], 
  cluster_rows=TRUE, 
  show_rownames=TRUE,
  cluster_cols=TRUE,
  annotation_col=df,
  clustering_distance_rows="correlation"
)

#Spearman correlation, values rescaled by mean
rescaled <- assay(vsd) - rowMeans(assay(vsd))
pheatmap(
  rescaled[top50,], 
  cluster_rows=TRUE, 
  show_rownames=TRUE,
  cluster_cols=TRUE,
  annotation_col=df,
  clustering_distance_rows="correlation"
)

#MA plot
plotMA(dose_shrink)


