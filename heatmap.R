install.packages("pheatmap")
library(pheatmap)

df = read.csv("input.csv",header = T,sep = ",",row.names = 1,fill=T)

pheatmap(df, 
         scale = "row", # 指定归一化的方式。"row"按行归一化，"column"按列归一化，"none"不处理
         cluster_rows = TRUE, # 是否对行聚类
         cluster_cols = FALSE, # 是否对列聚类
         clustering_method = "mcquitty", #指定聚类方法，还有ward,ward.D,ward.D2,single,average,mcquitty,median,centroid
         annotation_legend=TRUE, # 是否显示图例
         legend_breaks = c(-4, 0, 4), #设置断点和断点处标签
         border_color = NA, #设置边框颜色，NA表示没有
         color = colorRampPalette(c('#f0f0f0','#e0ecf4','#3182bd'))(50), # 指定热图的颜色
#         color = colorRampPalette(c('#fff7ec','#fee0d2','#ef6548'))(50), # 指定热图的颜色
         show_colnames = TRUE, # 是否显示列名
         show_rownames= TRUE,  # 是否显示行名
         fontsize=9, # 字体大小
