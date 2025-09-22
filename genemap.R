install.packages("gggenes")

library(ggplot2)
library(gggenes)

gene_colors <- c("Gene1" = "#66c2a5", "Gene2" = "#fc8d62", "Gene3" = "#8da0cb", "Gene4" = "#e78ac3", "Gene5" = "#a6d854", "Gene6" = "#ffd92f", "Capping enzymes" = "#e5c494", "Gene7" = "#b3b3b3")

data <- read.table("input.csv",sep=",",header=1)
p <- ggplot(data, aes(xmin = start, xmax = end, y = genome, fill = gene, forward = orientation)) +
  geom_gene_arrow(arrowhead_width = unit(8, "mm"), arrowhead_height = unit(12, "mm"), arrow_body_height = unit(6, "mm")) +  # 增加箭头的高度和宽度
  facet_wrap(~ genome, scales = "free", ncol = 1) +
  scale_fill_manual(values = gene_colors) +
  theme_genes()

# 保存绘图到 PDF 文件
pdf("output.pdf", width = 12, height = 160)
print(p)
dev.off()
