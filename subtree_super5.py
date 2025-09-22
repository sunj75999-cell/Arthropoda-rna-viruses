import os
import subprocess
from Bio import Phylo
from Bio.Phylo.BaseTree import Clade

# 参数配置
tree_file = "tree.newick"
fasta_dir = "clusters"  # 原始RdRp蛋白文件夹
output_dir = "subtree"
cut_height = 0.2

# 创建输出目录
os.makedirs(output_dir, exist_ok=True)

# Step 1: 加载Newick树
with open(tree_file) as f:
    tree = Phylo.read(f, "newick")

# Step 2: 提取树的子树（根据阈值）
def get_subtrees_by_height(tree, threshold):
    subtrees = []

    def traverse(clade: Clade, current_depth: float):
        if current_depth >= threshold:
            tips = [leaf.name for leaf in clade.get_terminals() if leaf.name]
            if len(tips) > 0:
                subtrees.append(set(tips))
            return  # 不再向下递归

        for child in clade.clades:
            branch_len = child.branch_length or 0.0
            traverse(child, current_depth + branch_len)

    traverse(tree.root, 0.0)
    return subtrees

groups = get_subtrees_by_height(tree, cut_height)
print(f"\n✅ 提取出 {len(groups)} 个子树 group（深度阈值为 {cut_height}）\n")

# Step 3: 遍历每组 group，汇总并执行 MUSCLE super5
perms = ["none", "abc", "acb", "bca"]
perturbs = ["0", "1", "2", "3"]

for i, group in enumerate(groups):
    group_id = f"group_{i+1:04d}"
    merged_input = os.path.join(output_dir, f"{group_id}.fasta")
    print(f"📦 处理 {group_id}，共 {len(group)} 个叶子...")

    with open(merged_input, 'w') as out_f:
        for name in group:
            fasta_file = os.path.join(fasta_dir, f"{name}.faa")
            if os.path.exists(fasta_file):
                with open(fasta_file) as in_f:
                    out_f.write(in_f.read())
            else:
                print(f"  ⚠️ 缺失文件: {fasta_file}")

    # 无论多少叶子，均进行 muscle super5
    for perm in perms:
        for perturb in perturbs:
            tag = f"{perm}_{perturb}"
            output_afa = os.path.join(output_dir, f"{group_id}_{tag}.afa")
            print(f"  → MUSCLE super5: {group_id} [{tag}]")
            try:
                subprocess.run([
                    "conda", "run", "-n", "TREE", "muscle", "-super5", merged_input,
                    "-perm", perm,
                    "-perturb", perturb,
                    "-output", output_afa
                ], check=True)
                print(f"    ✅ 输出成功: {output_afa}")
            except subprocess.CalledProcessError:
                print(f"    ❌ MUSCLE 失败: {group_id} [{tag}]")

print("\n🎉 所有 group 已处理完毕")
