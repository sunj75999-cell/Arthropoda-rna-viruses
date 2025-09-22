# 加载 igraph 和 RColorBrewer
library(igraph)
library(RColorBrewer)

# 读取 BLAST/MMseqs2 结果
edges <- read.table("mmseqs.m8", header=FALSE, sep="\t", stringsAsFactors=FALSE)
colnames(edges) <- c("Protein1", "Protein2", "Evalue")

# 计算相似性得分 (取 -log10(E-value))
edges$Similarity <- -log10(edges$Evalue)
max_finite <- max(edges$Similarity[is.finite(edges$Similarity)], na.rm=TRUE)
edges$Similarity[is.infinite(edges$Similarity)] <- max_finite + 1  # 只比最大值稍大

# 归一化边宽（缩放到 1-10）
edges$Similarity <- scale(edges$Similarity, center=FALSE)
edges$EdgeWidth <- (edges$Similarity - min(edges$Similarity)) / 
  (max(edges$Similarity) - min(edges$Similarity)) * 9 + 1

# 构建图
g <- graph_from_data_frame(edges, directed=FALSE)

# 运行 Girvan-Newman 聚类算法（也可替换为 cluster_edge_betweenness）
clusters <- cluster_edge_betweenness(g)
#clusters <- cluster_fast_greedy(g) # 可选的另一种聚类方法
#clusters <- cluster_louvain(g)

# 获取社区成员信息
membership_df <- data.frame(Protein=V(g)$name, Cluster=membership(clusters))

# 保存社区划分信息
write.csv(membership_df, "Clusters.csv", row.names=FALSE)

# 分配颜色（根据社区数自动选择）
num_clusters <- length(unique(membership(clusters)))
colors <- colorRampPalette(brewer.pal(12, "Set3"))(num_clusters)
V(g)$color <- colors[membership(clusters)]

# 设置布局（固定布局更美观）
layout <- layout_with_fr(g)

# 绘图
plot(g, layout=layout,
     vertex.color=membership(clusters),
     vertex.label=NA,
     vertex.size=5,
     edge.width=edges$EdgeWidth/10,
     main="Girvan-Newman 分群后的 RdRP 网络")

# 添加凸包显示每个社区区域
library(scales)
for (c in unique(membership(clusters))) {
  nodes_in_c <- which(membership(clusters) == c)
  if (length(nodes_in_c) >= 3) {
    coords <- layout[nodes_in_c, ]
    ch <- chull(coords)
    polygon(coords[ch, ], col=alpha(rainbow(length(clusters))[c], 0.2), border=NA)
  }
}

# 可选：添加图例
legend("topright", legend=paste("Supergroup", 1:num_clusters), fill=colors[1:num_clusters], cex=0.8)
