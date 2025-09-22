library("seqinr")
library("plyr")
library("gsubfn")
library("Rsamtools")
library("reshape2")
library("seqLogo")
library("motifStack")
library("S4Vectors")
library("Rcpp")
library("dplyr")
library("ggplot2")
library("tidyr")
# 加载 viRome 函数
source("https://raw.githubusercontent.com/mw55309/viRome_legacy/main/R/viRome_functions.R")

# 输入 BAM 文件路径
infile <- "input"

# 读取 BAM 文件 (指定染色体)
bam <- read.bam(infile, chr = "contig")
# 添加一个长度列 (通过POS和QNAME或其他字段计算；如果已存在，请忽略)
bam_1 <- bam %>%
  mutate(length = nchar(seq))  # 假设 seq 字段代表读取长度
# 提取每个读取的碱基，按长度和链方向分组
base_fractions <- bam_1 %>%
  mutate(seq_base = strsplit(as.character(seq), "")) %>%  # 拆分每个序列的碱基
  unnest(seq_base) %>%  # 展开为每个碱基一行
  group_by(length, strand, seq_base) %>%  # 按长度和链方向分组
  summarise(count = n()) %>%  # 统计每个碱基的数量
  ungroup() %>%
  group_by(length, strand) %>%  # 按长度和链方向计算比例
  mutate(proportion = count / sum(count)) %>%  # 计算碱基比例
  select(length, strand, base = seq_base, proportion)  # 重命名列

# 按照长度和链方向分组并统计数量
length_strand_counts <- bam_1 %>%
  group_by(length, strand) %>%
  summarise(count = n(), .groups = "drop")
combined_data <- merge(length_strand_counts, base_fractions, by = c("length", "strand"))

# 计算每种碱基的绝对数量
combined_data <- combined_data %>%
  mutate(absolute_count = count * proportion)  # 绝对数量 = 正负链数量 × 碱基比例


# 绘图
ggplot() +
  # 对于正链，调整 y 值方向，翻转为从下往上
  geom_bar(data = subset(combined_data, strand == "+"),
           aes(x = as.factor(length), y = -absolute_count, fill = base),  # 对正链数据进行y值取反
           stat = "identity", position = "stack", width = 0.8) +
  # 对于反链，保持 y 值方向不变
  geom_bar(data = subset(combined_data, strand == "-"),
           aes(x = as.factor(length), y = absolute_count, fill = base),
           stat = "identity", position = "stack", width = 0.8) +
  facet_wrap(~strand, ncol = 1, labeller = labeller(strand = c("+" = "Sense", "-" = "Antisense"))) +
  scale_y_continuous(
    name = "Reads Count", 
    labels = abs,  # 使用绝对值显示 y 轴标签
    expand = expansion(mult = c(0.05, 0.05))
  ) +
