#!/bin/bash

# 设置文件夹路径
hhr_dir="hhr"
output_file="score_results.csv"

# 输出文件表头
echo "Query,Target,Score" > "$output_file"

# 遍历所有的 .hhr 文件
for hhr_file in "$hhr_dir"/*.hhr; do
    # 获取文件名，按第二个下划线分割
    filename=$(basename "$hhr_file" .hhr)

    # 提取 Query 和 Target
    query=$(echo "$filename" | cut -d'_' -f1)
    target=$(echo "$filename" | cut -d'_' -f2)

    # 提取第十行的第58到64个字符，这里我们去掉可能的空格
    score=$(sed -n '10p' "$hhr_file" | cut -c58-64 | tr -d '[:space:]')

    # 如果 Score 存在并且非空，则写入输出文件
    if [ -n "$score" ]; then
        echo "$query,$target,$score" >> "$output_file"
    else
        echo "未找到Score: $query,$target" # 如果没有找到Score，则输出警告
    fi
done

echo "✅ 完成！结果保存在 $output_file"
