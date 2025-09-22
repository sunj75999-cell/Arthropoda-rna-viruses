#!/bin/bash

# ================================================
# 综合聚类序列处理脚本（清洗 + MSA扰动 + maxcc比对）
# ================================================
# 输入与输出路径设置
input_dir="clusters"
cleaned_dir="cleaned_clusters"
idmap_dir="idmaps"
perm_efa_dir="msa_efa_perm"
final_afa_dir="msa_best"

# 创建所有需要的输出目录
mkdir -p "$cleaned_dir" "$idmap_dir" "$perm_efa_dir" "$final_afa_dir"

# 定义排列组合和扰动数
perms=("none" "abc" "acb" "bca")
perturbs=(0 1 2 3)

# 遍历每个 cluster 的 fasta 文件
for faa in "$input_dir"/*.faa; do
    cluster=$(basename "$faa" .faa)
    cleaned="$cleaned_dir/${cluster}.faa"
    idmap="$idmap_dir/${cluster}.idmap.tsv"

    # 预处理：清洗并重命名序列ID
    > "$cleaned"
    echo -e "Original_ID\tNew_ID" > "$idmap"
    i=1
    while read line; do
        if [[ $line == ">"* ]]; then
            orig_id=$(echo "$line" | sed 's/^>//')
            new_id="${cluster}_seq${i}"
            echo ">$new_id" >> "$cleaned"
            echo -e "$orig_id\t$new_id" >> "$idmap"
            ((i++))
        else
            echo "$line" >> "$cleaned"
        fi
    done < "$faa"

    # 创建当前聚类的输出子目录
    cluster_dir="${perm_efa_dir}/${cluster}"
    mkdir -p "$cluster_dir"

    echo "▶ 正在处理 $cluster：执行 16 次扰动排列比对..."

    # Step 1: 运行 16 次 muscle -super5
    for perm in "${perms[@]}"; do
        for perturb in "${perturbs[@]}"; do
            output_afa="${cluster_dir}/${perm}_${perturb}.afa"
            echo "  → $perm $perturb"
            muscle -super5 "$cleaned" -perm "$perm" -perturb "$perturb" -output "$output_afa"
        done
    done

    # Step 2: 标注每个对齐文件开头
    for perm in "${perms[@]}"; do
        for perturb in "${perturbs[@]}"; do
            output_afa="${cluster_dir}/${perm}_${perturb}.afa"
            sed -i "1s/^/<${perm}_${perturb}\n/" "$output_afa"
        done
    done

    # Step 3: 合并所有扰动对齐为 .efa
    merged_efa="${cluster_dir}/merged.efa"
    cat "$cluster_dir"/*.afa > "$merged_efa"

    # Step 4: 提取 maxcc 最优比对结果
    final_out="${final_afa_dir}/${cluster}.afa"
    echo "  ✔ 运行 maxcc → $final_out"
    muscle -maxcc "$merged_efa" -output "$final_out"

done

echo "✅ 所有聚类处理完成，最佳比对文件保存在 $final_afa_dir/"
