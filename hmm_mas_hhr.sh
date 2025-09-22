#!/bin/bash

# 输入：maxcc 输出的最佳 MSA
input_dir="msa_best"   # 存放 MSA 文件的目录
a3m_dir="msa_a3m"      # 转换后的 A3M 文件存放目录
hmm_dir="hmm"          # HMM 文件存放目录
hhr_dir="hhr"          # HHR 输出文件存放目录
matrix_out="HMM_distance_matrix.csv"  # 距离矩阵输出路径

# 创建必要的目录
mkdir -p "$a3m_dir" "$hmm_dir" "$hhr_dir"

# Step 1: 转换 AFA 为 A3M 格式
echo "▶ Step 1: 转换 AFA 为 A3M..."
for f in "$input_dir"/*.afa; do
    base=$(basename "$f" .afa)
    reformat.pl fas a3m "$f" "$a3m_dir/${base}.a3m"
done

# Step 2: 构建 HMM 文件
echo "▶ Step 2: 构建 HMM..."
for f in "$a3m_dir"/*.a3m; do
    base=$(basename "$f" .a3m)
    hhmake -i "$f" -o "$hmm_dir/${base}.hmm"
done

# Step 3: HMM-HMM 全对全比对，包括自比
echo "▶ Step 3: HMM-HMM 全对全比对，包括自比..."

hmm_files=($hmm_dir/*.hmm)

# 遍历每对 HMM 文件，进行比对
for ((i=0; i<${#hmm_files[@]}; i++)); do
    for ((j=i; j<${#hmm_files[@]}; j++)); do  # 修改此行，让每个 HMM 自比
        query=${hmm_files[$i]}
        target=${hmm_files[$j]}
        query_base=$(basename "$query" .hmm)
        target_base=$(basename "$target" .hmm)

        # 执行 hhalign 比对
        echo "正在比对 $query_base 与 $target_base"
        hhalign -i "$query" -t "$target" -o "$hhr_dir/${query_base}_${target_base}.hhr" -v 0
    done
done

echo "✅ 所有比对完成！"
