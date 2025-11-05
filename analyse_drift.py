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
    "sim_data/2025-10-19_largest-drift-hom0_seeds0-100combined.csv",
    delimiter=",",
    # skiprows=0,
)

dff = df.loc[df["[step]"] == 1e5]


# %%
#################################
#####  Exploration   #####
#################################
def calcEx(x):
    a = json.loads(x["final-opinions"].replace(" ", ","))
    b = np.abs(np.array(a) - 0.5)
    return np.mean(b)


def calcStd(x):
    a = json.loads(x["final-opinions"].replace(" ", ","))
    b = np.std(a)
    return b


out = "extremeness"
dff.loc[:, out] = dff.apply(calcEx, axis="columns")

fig = plt.figure()
ax = plt.axes()
sns.heatmap(
    dff.pivot_table(
        index="confidence-bound", columns="sigma-ambiguity-within-group", values=out
    ),
    vmin=0,
    vmax=0.5,
    cbar_kws={"label": out},
    annot=True,
    fmt=".2f",
)  # hue=out, palette="viridis")
ax.set_xlabel("ambiguity-noise")
ax.set_ylabel("confidence-bound")
print(f"homophily = {dff.homophily.unique()}; seeds = {dff.seed.unique()}")


out = "standard-deviation"
dff.loc[:, out] = dff.apply(calcStd, axis="columns")


fig = plt.figure()
ax = plt.axes()
sns.heatmap(
    dff.pivot_table(
        index="confidence-bound", columns="sigma-ambiguity-within-group", values=out
    ),
    vmin=0,
    vmax=0.5,
    cbar_kws={"label": out},
    annot=True,
    fmt=".2f",
    cmap="viridis",
)
ax.set_xlabel("ambiguity-noise")
ax.set_ylabel("confidence-bound")

# %%


# %%
#################################
#####  DRIFT   #####
#################################
# define drift as 80% are >0.65 or <0.35
out = r"Simulations with Drift"
percTh = 0.8
exTh = 0.15


def drift(ops):
    ops = np.array(json.loads(ops["final-opinions"].replace(" ", ",")))
    return ((ops > 0.5 + exTh).mean() > percTh) or ((ops < 0.5 - exTh).mean() > percTh)


dff.loc[:, out] = dff.apply(
    drift,
    axis="columns",
)

# Alternative Definition
# drift as consensus (std <0.1) + mean >0.6 or <0.4
# out = "Simulations with Drift\n(high extremeness & low diversity)"
# dff[out] = (dff["extremeness"] > 0.15) & (dff["standard-deviation"] < 0.1)


fig = plt.figure(figsize=(12 / 2.54, 8 / 2.54))
ax = plt.axes()
sns.heatmap(
    dff.pivot_table(
        index="confidence-bound",  # confidenceBound
        columns="sigma-ambiguity-within-group",  # ingroupAmbiguity
        values=out,
        aggfunc="mean",
    ),
    vmin=0,
    vmax=0.5,
    cbar_kws={"label": out, "extend": "max"},
    cmap="Greys",
    annot=True,
    fmt=".0%",
)
cbar = ax.collections[0].colorbar
cbar.ax.tick_params(labelsize=8)
cbar.set_ticklabels([f"{x:.0%}" for x in cbar.get_ticks()])
ax.figure.axes[-1].yaxis.label.set_size(10)
ax.set_xlabel("$ambiguity$", fontsize=10)
ax.set_ylabel("$confidenceBound$", fontsize=10)
ax.spines["left"].set_visible(True)
ax.spines["bottom"].set_visible(True)
ax.set_xticks(np.arange(0, 7, 1), minor=True)
ax.set_yticks(np.arange(0, 8, 1), minor=True)
ax.grid(which="minor")
plt.tight_layout()
plt.savefig("figs/drift.pdf", dpi=600)
# %%
