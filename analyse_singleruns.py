# %%
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import json

plt.rcParams.update({"font.size": 10})
plt.rcParams.update({"font.size": 10})
plt.rcParams["xtick.labelsize"] = 8
plt.rcParams["ytick.labelsize"] = 8


def plot_single(df, ax, hom, eps, nu, mean=True):
    a = df.loc[
        (
            (df["homophily"] == hom)
            & (df["confidence-bound"] == eps)
            & (df["sigma-ambiguity-within-group"] == nu)
        )
    ]
    r = []
    for t in a["[step]"].unique():
        ops = json.loads(
            a.loc[a["[step]"] == t, "final-opinions"].iloc[0].replace(" ", ",")
        )
        r.append([t] + ops)
    r = pd.DataFrame(r, columns=["time"] + list(range(100)))
    r = r.set_index("time")
    linestyles = "-"
    r.plot(lw=0.8, color=color, alpha=0.3, legend=False, ax=ax, ls=linestyles)

    if mean:
        r.mean(axis=1).plot(color="k", ax=ax)
        ax.fill_between(
            r.index,
            r.mean(axis=1) - r.std(axis=1),
            r.mean(axis=1) + r.std(axis=1),
            color="k",
            alpha=0.2,
            zorder=-1,
        )


# %%

seed = 13
df = pd.read_table(
    f"sim_data/2025-10-21_singleRun_seed{seed}.csv", delimiter=",", skiprows=6
)

color = "grey"
fig = plt.figure(figsize=(12 / 2.54, 6 / 2.54))
ax = plt.axes()
plot_single(df, ax, 0.0, 0.2, 0.1, True)
ax.set_xlabel("time")
ax.set_ylabel("opinion space")
ax.set_ylim(0, 1)
ax.set_xlim(0, 1e5)
ax.set_xticks([0, 5e4, 1e5])
plt.savefig(f"figs/singleRun_randomNet_seed{seed}.pdf", dpi=600)
# %%

#################################
#####  is this single run a sim with DRIFT?   #####
#################################
ex_treshhold = 0.15
perc_treshold = 0.8
ops = json.loads(
    df.loc[df["[step]"] == 1e5]["final-opinions"].iloc[0].replace(" ", ",")
)
drift = lambda x: ((np.array(x) > 0.5 + ex_treshhold).mean() > perc_treshold) + (
    (np.array(x) < 0.5 - ex_treshhold).mean() > perc_treshold
)
drift(ops), (np.array(ops) < 0.5 - ex_treshhold).mean(), (
    np.array(ops) > 0.5 + ex_treshhold
).mean()
# %%

#################################
#####  2x2 homophily and ambiguity   #####
#################################
seed = 24
dfs = pd.read_table(
    f"sim_data/2025-10-21_singleRuns_homExp_seed{seed}.csv", delimiter=",", skiprows=6
)
color = "grey"
eps = 0.2
fig, axs = plt.subplots(2, 2, sharex=True, sharey=True, figsize=(12 / 2.54, 9 / 2.54))
plot_single(
    dfs,
    axs[0, 0],
    0.0,
    eps,
    0.0,
    False,
)
plot_single(dfs, axs[1, 0], 0.95, eps, 0.0, False)
plot_single(dfs, axs[0, 1], 0.0, eps, 0.1, False)
plot_single(dfs, axs[1, 1], 0.95, eps, 0.1, False)

ax = axs[0, 0]
ax.set_xlabel("time", fontsize=10)
ax.set_ylabel("opinion space", fontsize=10)
axs[1, 0].set_ylabel("opinion space", fontsize=10)
ax.set_ylim(0, 1)
xmax = 4e4
ax.set_xlim(0, 4e4)
ax.set_xticks([0, xmax / 2, xmax])
axs[0, 0].text(
    xmax / 2, 1.1, f"$ambiguity={0.0}$", va="center", ha="center", fontsize=10
)
axs[0, 1].text(
    xmax / 2, 1.1, f"$ambiguity={0.1}$", va="center", ha="center", fontsize=10
)

axs[0, 1].text(
    1.1 * xmax,
    0.5,
    f"$homophily={0.0}$",
    rotation=90,
    va="center",
    ha="center",
    fontsize=10,
)
axs[1, 1].text(
    1.1 * xmax,
    0.5,
    f"$homophily={0.95}$",
    rotation=90,
    va="center",
    ha="center",
    fontsize=10,
)
fig.tight_layout()
plt.savefig(f"figs/singlerun_homExp_seed{seed}.pdf", dpi=600)

# %%

a = dfs.loc[
    (
        (dfs["homophily"] == 0.95)
        & (dfs["confidence-bound"] == 0.2)
        & (dfs["sigma-ambiguity-within-group"] == 0.1)
    )
]
ops = json.loads(a.loc[a["[step]"] == 1e5]["final-opinions"].iloc[0].replace(" ", ","))
drift = lambda x: ((np.array(x) > 0.65).mean() > 0.8) + (
    (np.array(x) < 0.35).mean() > 0.8
)
drift(ops), (np.array(ops) < 0.35).mean(), (np.array(ops) > 0.65).mean()


extremeness = np.mean(abs(np.array(ops) - 0.5))
ingroupdiversity = (np.std(np.array(ops[:50])) + np.std(np.array(ops[50:]))) / 2
overalldiversity = np.std(np.array(ops))
pol0 = np.mean(np.array(ops)[:50]) - np.mean(np.array(ops)[50:])

print(
    "; ".join(
        [
            f"{a}: {eval(a)}"
            for a in ["extremeness", "ingroupdiversity", "overalldiversity", "pol0"]
        ]
    )
)

# %%
