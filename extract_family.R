# 加载必要的库
library(dplyr)

# 读取 CSV 文件（请将 your_file.csv 替换为你的实际文件名）
data <- read.csv("C:/Users/40743/Desktop/family_abundance.csv")

# 确保第一列为因子或字符类型，其余列为数值类型
data[[1]] <- as.factor(data[[1]])  # 将第一列转换为因子类型

# 对每个分类的数值列求和
summarized_data <- data %>%
  group_by(Class = data[[1]]) %>%  # 根据第一列分组
  summarise(across(where(is.numeric), sum, na.rm = TRUE))  # 对数值列求和，忽略 NA 值

# 输出结果到新的 CSV 文件
write.csv(summarized_data, "output_dir", row.names = FALSE)
