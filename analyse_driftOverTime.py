"""
Peter Steiglechner, 2025-10
This code reproduces a Figure for a book chapter

Steiglechner, P. & Keijzer, M.A. (2026). Opinion dynamics with ambiguous messages within and between identity groups. In Larson & Coen (Eds.). Agent-Based Modeling for Research on Groups, Networks, and Organizations. APA Publishing

The model simulates opinion formation under bias and noise of agents with identities.
Bias is a simple bounded confidence model.
Noise is ambiguity in the message, conceptualised as random Gaussian noise in the communicated opinion.
Identity is a category.
The level of noise can depend on identity (ingroup/outgroupAmbiguity)
The interaction network is created as follows: each identity group is fully connected, then using Maslov-Sneppen rewiring to create between-group links such that we reach a fraction of in-group to between-group links specified by the paramter homophily

Experiment:
["ingroupAmbiguity" 0.1]
["outgroupAmbiguity" 0.1]
["confidenceBound" 0.2]
["uniform-initial-opinion" true]
["homophily" 0]
["seed" [0 1 99]]

convergenceRate 0.5
num-agents 100

Here, we visualise the degree of drift over time.
"""

# %%

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

import json


plt.rcParams.update({"font.size": 10})
plt.rcParams["xtick.labelsize"] = 8
plt.rcParams["ytick.labelsize"] = 8


df = pd.read_table(
    "sim_data/2025-11-02_driftoverTime.csv",
    delimiter=",",
    skiprows=6,
)

# %%
# define drift as consensus (std <0.1) + mean >0.6 or <0.4
out = "drift"
# dff[out] = (dff["extremeness"] > 0.15) & (dff["standard-deviation"] < 0.1)

# define drift as 80% are >0.65 or <0.35
percTh = 0.8
exTh = 0.2
out = r"Simulations with Drift"


def drift(ops):
    ops = np.array(json.loads(ops["final-opinions"].replace(" ", ",")))
    return ((ops > 0.5 + exTh).mean() > percTh) or ((ops < 0.5 - exTh).mean() > percTh)


df.loc[:, out] = df.apply(
    drift,
    axis="columns",
)


n_sims = len(df["seed"].unique())
fig = plt.figure(figsize=(12 / 2.54, 8 / 2.54))
ax = plt.axes()
(df.groupby("[step]")[out].sum() / n_sims * 100).plot(
    marker="o", color="grey", clip_on=False
)
ax.set_xlabel(r"time $t$", fontsize=10)
ax.set_ylabel(r"Simulations with drift [%]", fontsize=10)
ax.set_xticks([0, 5e4, 1e5, 1.5e5, 2e5])
ax.set_xticklabels(
    [
        r"$0$",
        r"$0.5\cdot 10^5$",
        r"$1.0\cdot 10^5$",
        r"$1.5\cdot 10^5$",
        r"$2.0\cdot 10^5$",
    ]
)
ax.set_ylim(
    0,
)
ax.set_xlim(0, 2e5)
plt.tight_layout()
plt.savefig("figs/drift_over_time.pdf", dpi=600)
# %%
