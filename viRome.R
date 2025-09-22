install.packages(c("BiocManager","Rcpp","seqinr","plyr","gsubfn","Rsamtools","reshape2","seqLogo", "motifStack", "S4Vectors"))
install.packages("devtools")
BiocManager::install("seqLogo")
BiocManager::install("motifStack")
BiocManager::install("Rsamtools")

library("seqinr")
library("plyr")
library("gsubfn")
library("Rsamtools")
library("reshape2")
library("seqLogo")
library("motifStack")
library("S4Vectors")
library("Rcpp")
source("https://raw.githubusercontent.com/mw55309/viRome_legacy/main/R/viRome_functions.R")
infile <- "input"
#infile <- "input.bam"
bam <- read.bam(infile, chr="contig")
#只需要 read.bam() 的输出
bamc <- clip.bam(bam)
#只需要clip.bam()的输出
bpl <- barplot.bam(bamc)
#仅需要 barplot.bam() 的输出
ssp <- size.strand.bias.plot(bpl)
#只需要clip.bam()的输出
dm <- summarise.by.length(bamc)
sph <- size.position.heatmap(dm)
#只需要 summarise.by.length() 的输出
sbp <- stacked.barplot(dm)
#只需要clip.bam()的输出
#虽然应该改变 minlen, maxlen
#并反思
sir <- position.barplot(bamc)
# requires only the output of clip.bam()
sr <- sequence.report(bamc)
# requires only the output of clip.bam()
pwm <- make.pwm(bamc)
# requires only the output of make.pwm()
pmh <- pwm.heatmap(pwm)
# requires only the output of sequence.report()
rdp <- read.dist.plot(sr)
