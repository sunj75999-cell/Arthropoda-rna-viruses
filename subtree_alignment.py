import os
import subprocess
from Bio import Phylo
from io import StringIO
import uuid

# 参数配置
msa_dir = "msa_best"
tree_file = "tree.newick"
output_dir = "subtree_alignments"
cut_height = 0.2
rt_clusters = set()

# 创建输出目录
os.makedirs(output_dir, exist_ok=True)

# Step 1: 读取 Newick 树文件
with open(tree_file) as f:
    tree = Phylo.read(f, "newick")

# 标准化终端节点名（以防缺前缀）
#for node in tree.get_terminals():
#    if not str(node.name).startswith("cluster_"):
#       node.name = f"{node.name}"

# 函数：收集所有子树中距离 < threshold 的集合
def collect_subtrees(node, threshold):
    def walk(n, acc_len=0.0):
        if n.is_terminal():
            return [(n.name, acc_len)]
        left = walk(n.clades[0], acc_len + (n.clades[0].branch_length or 0))
        right = walk(n.clades[1], acc_len + (n.clades[1].branch_length or 0))
        combined = left + right
        max_depth = max(d for _, d in combined)
        if max_depth <= threshold:
            return combined  # 返回 [(name, length)]
        return combined
    return [set(n for n, _ in walk(clade)) for clade in node.clades]

# 获取子树
groups = collect_subtrees(tree.root, threshold=cut_height)
groups = [g for g in groups if len(g) > 1]

print(f"✅ {len(groups)} subtrees identified.")

# Step 2: 遍历每个子树组，合并并比对
for i, group in enumerate(groups):
    group_id = f"group_{i+1:04d}"
    merged_input = os.path.join(output_dir, f"{group_id}.fasta")
    efa_file = merged_input.replace(".fasta", ".efa")
    maxcc_file = merged_input.replace(".fasta", "_maxcc.afa")

    valid_files = []
    print(f"\n📦 Processing {group_id}...")
    for name in group:
        msa_path = os.path.join(msa_dir, f"{name}.afa")
        if name in rt_clusters:
            print(f"  ⏭️ Skipped RT cluster: {name}")
        elif not os.path.isfile(msa_path):
            print(f"  ❌ MSA file not found: {msa_path}")
        else:
            valid_files.append(msa_path)
            print(f"  ✅ Using {name}.afa")

    if len(valid_files) < 2:
        print(f"⚠️  Skipping {group_id}: only {len(valid_files)} valid sequences.")
        continue

    # 写入合并后的 MSA
    with open(merged_input, 'w') as out_f:
        for f in valid_files:
            with open(f) as in_f:
                out_f.write(in_f.read())

    print(f"🔄 Aligning: {group_id} with {len(valid_files)} clusters...")

    try:
        subprocess.run(["conda", "run", "-n", "TREE", "muscle",
                        "-align", merged_input,
                        "-stratified",
                        "-output", efa_file], check=True)

        subprocess.run(["conda", "run", "-n", "TREE", "muscle",
                        "-maxcc", efa_file,
                        "-output", maxcc_file], check=True)

        print(f"✅ {group_id} alignment done: {maxcc_file}")

    except subprocess.CalledProcessError:
        print(f"❌ MUSCLE failed on {group_id}, skipping...")
