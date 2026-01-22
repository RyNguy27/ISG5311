library(biomaRt)
library(clusterProfiler)
library(enrichplot)
library(GO.db)
library(dplyr)
library(ggupset)
library(ggridges)


###if not installed###
#install.packages("BiocManager")
#BiocManager::install("biomaRt")
#BiocManager::install("clusterProfiler")
#BiocManager::install("enrichplot")

listEnsemblArchives()

# this code isn't being run here because of connectivity issues at the time of compilation. 
ensemblhost <- "https://may2024.archive.ensembl.org"
listMarts(host=ensemblhost)

ensemblhost <- "https://may2024.archive.ensembl.org"
mart <- useEnsembl(biomart = "ENSEMBL_MART_ENSEMBL", dataset = "mmusculus_gene_ensembl", host = ensemblhost)


listDatasets(mart) %>%
  head()

searchDatasets(mart,pattern="mmusculus")

# store dataset name
musdata <- searchDatasets(mart,pattern="mmusculus")[1,1]
# select a mirror: 'www', 'uswest', 'useast', 'asia'
mus_mart <- useEnsembl(biomart = "ENSEMBL_MART_ENSEMBL", dataset = musdata, mirror = "useast")

searchAttributes(mart = mus_mart, pattern = "ensembl_gene_id")

searchFilters(mart = mus_mart, pattern="ensembl")

# gene names and ts length
ann <- getBM(
  filter="ensembl_gene_id",
  value=rownames(dose),
  attributes=c("ensembl_gene_id","description","transcript_length"),
  mart=mus_mart
)

# pick only the longest transcript for each gene ID
ann <- group_by(ann, ensembl_gene_id) %>% 
  summarize(.,description=unique(description),transcript_length=max(transcript_length)) %>%
  as.data.frame()

# get GO term info
# each row is a single gene ID to GO ID mapping, so the table has many more rows than genes in the analysis
go_ann <- getBM(
  filter="ensembl_gene_id",
  value=rownames(dose),
  attributes=c("ensembl_gene_id","description","go_id","name_1006","namespace_1003"),
  mart=mus_mart
)

# ignore rows with empty gene descriptions
filter(ann, description!="") %>% head()

head(go_ann)


# Add gene names to DE results
dose_shrink_ann <- dose_shrink %>% 
  as.data.frame() %>%
  rownames_to_column(var = "ensembl_gene_id") %>%
  left_join(., ann) %>%
  arrange(-abs(log2FoldChange))

head(dose_shrink_ann, n=10)

#######ENRICHMENT ANALYSIS###############

# get ENSEMBL gene IDs for genes with padj < 0.1
genes <- rownames(dose[which(dose$padj < 0.1),])
# get ENSEMBL gene IDs for universe (all genes with non-NA padj passed independent filtering)
univ <- rownames(dose[!is.na(dose$padj),])
# pull out the columns of go_ann containing GO IDs and descriptions, keep only unique entries. 
gonames <- unique(go_ann[,c(3,4)]) %>% unique()

dose_enrich <- enricher(
  gene=genes,
  universe=univ,
  TERM2GENE=go_ann[,c(3,1)],
  TERM2NAME=gonames
)

as.data.frame(dose_enrich)

# extract log2 fold changes, only for genes that passed independent filtering. 
l2fcs <- as.data.frame(dose) %>%
  filter(!is.na(padj)) %>%
  dplyr::select(log2FoldChange)

# put log2FCs in a vector, add gene IDs as names, sort 
l2fcvec <- l2fcs[,1]
names(l2fcvec) <- rownames(l2fcs)
l2fcvec <- sort(l2fcvec, decreasing=TRUE)

dose_gsea <- GSEA(
  geneList=l2fcvec,
  TERM2GENE=go_ann[,c(3,1)],
  TERM2NAME=gonames
) 

##Upregulated term
gseaplot(dose_gsea, by = "all", title = dose_enrich$Description[4], geneSetID = 4)

##Down-regulated term
gseaplot(dose_gsea, by = "all", title = dose_enrich$Description[1], geneSetID = 1)

as.data.frame(dose_gsea)

##Dotplots

dotplot(dose_enrich)

dotplot(dose_gsea)

##Upset plots

upsetplot(dose_enrich)

upsetplot(dose_gsea)

##Ridgeplots

ridgeplot(dose_gsea,label_format=30)

##Gene-concept network

cnetplot(dose_gsea, showCategory=10, foldChange=l2fcvec, cex_label_gene=0.5)

