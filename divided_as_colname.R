install.packages("dplyr")
# 加载必要的包
library(readr) # 方便读写 CSV 文件
library(dplyr) # 用于数据操作
library(purrr)  # 用于批量操作

# 函数：根据第2列分类，将第一列的数据分别写入不同的 TXT 文件
process_csv_to_txt <- function(input_csv, output_dir) {
  # 创建输出目录（如果不存在）
  if (!dir.exists(output_dir)) {
    dir.create(output_dir)
  }
  
  # 读取 CSV 文件
  data <- read_csv(input_csv)
  
  # 检查是否存在至少 4 列
  if (ncol(data) < 2) {
    stop("输入的 CSV 文件至少需要有2列！")
  }
  
  # 获取第四列的列名
  colnames(data) <- tolower(colnames(data))  # 转为小写，避免大小写不一致的问题
  category_col <- colnames(data)[2]  # 获取第四列的列名（如果列名是category则会取得category）
  
  # 分组提取并输出为 TXT 文件
  data %>%
    group_by(across(all_of(category_col))) %>%  # 根据第四列进行分组
    group_split() %>%
    walk(function(group) {
      category_name <- unique(group[[category_col]])[1]
      output_file <- file.path(output_dir, paste0(category_name, ".txt"))
      write_lines(group[[1]], output_file)  # 写入第一列到 TXT 文件
    })
  message("处理完成！文件已生成到：", output_dir)
}

# 使用方法
 process_csv_to_txt("input", "output")
