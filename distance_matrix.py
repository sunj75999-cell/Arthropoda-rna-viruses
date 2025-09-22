import pandas as pd
import numpy as np

# 读取原始的 CSV 文件，文件中包含 Query、Target 和 Score
input_file = "score_results.csv"
output_file = "distance_matrix.csv"

# 读取数据
data = pd.read_csv(input_file)

# 获取所有的 cluster 名称（这里只有 14 个 cluster）
clusters = sorted(set(data['Query']).union(set(data['Target'])))

# 创建一个 14x14 的距离矩阵
distance_matrix = pd.DataFrame(np.nan, index=clusters, columns=clusters)

# 填充距离矩阵
for index, row in data.iterrows():
    query = row['Query']
    target = row['Target']
    score = row['Score']

    # 根据 Score 计算距离 (dAB = -ln(SAB / min(SAA, SBB)))
    # SAA 和 SBB 为目标自身的得分，这里从原数据中获取对应的 Score
    score_query = data[(data['Query'] == query) & (data['Target'] == query)]['Score'].values
    score_target = data[(data['Query'] == target) & (data['Target'] == target)]['Score'].values

    # 如果没有找到自身的得分，默认不使用
    if len(score_query) == 0 or len(score_target) == 0:
        score_query = 0
        score_target = 0
    else:
        score_query = score_query[0]
        score_target = score_target[0]

    # 计算最小得分
    min_self_score = min(score_query, score_target)
    # 计算距离
    if min_self_score > 0:  # 避免除零错误
        distance = -np.log(score / min_self_score)
    else:
        distance = np.nan  # 如果没有有效的 Score，则设为 NaN

    # 填充矩阵（对称填充）
    distance_matrix.loc[query, target] = distance
    distance_matrix.loc[target, query] = distance  # 对称填充

# 将距离矩阵保存为 CSV 文件
distance_matrix.to_csv(output_file)

print(f"✅ 距离矩阵已保存至：{output_file}")
