#!/bin/bash

# 设置路径
input_dir="input"  # 包含 group_XXXX_*.afa 的目录
output_dir="output"  # 输出 maxcc、修剪、建树的目录

mkdir -p "$output_dir"

echo "▶ Step 1: 遍历所有 group 进行 maxcc + TrimAl + IQ-TREE..."

# 遍历所有 group_XXXX（不重复）
for group_id in $(ls "$input_dir"/group_*.afa | sed -E 's/.*(group_[0-9]+)_.*/\1/' | sort -u); do
    merged_fasta="$output_dir/${group_id}.merged.fasta"
    maxcc_output="$output_dir/${group_id}_maxcc.afa"
    trimmed_output="$output_dir/${group_id}_trimmed.afa"
    iqtree_output_dir="$output_dir/${group_id}_iqtree"
    mkdir -p "$iqtree_output_dir"

    echo "🔄 合并 $group_id 的所有 super5 AFA..."

    > "$merged_fasta"  # 清空合并输出文件

    for file in "$input_dir/${group_id}"_*.afa; do
        fname=$(basename "$file" .afa)
        echo "<$fname" >> "$merged_fasta"
        cat "$file" >> "$merged_fasta"
    done

    # 若合并文件为空则跳过
    if [[ ! -s "$merged_fasta" ]]; then
        echo "❌ $group_id 无有效 MSA，跳过"
        continue
    fi

    # Step 1: MUSCLE maxcc
    echo "🔬 MUSCLE maxcc $group_id..."
    conda run -n TREE muscle -maxcc "$merged_fasta" -output "$maxcc_output"

    # Step 2: TrimAl 修剪
    echo "✂️ TrimAl 修剪 $group_id..."
    conda run -n TREE trimal -in "$maxcc_output" -out "$trimmed_output" -gt 0.2

    # Step 3: IQ-TREE 建树
    echo "🌲 IQ-TREE 构建 $group_id..."
    conda run -n TREE iqtree -s "$trimmed_output" -bb 3000 -nt AUTO -nm 3000 -pre "$iqtree_output_dir/iqtree_output"

    echo "✅ 完成 $group_id"
done

echo "🎉 所有子树构建完成！"
