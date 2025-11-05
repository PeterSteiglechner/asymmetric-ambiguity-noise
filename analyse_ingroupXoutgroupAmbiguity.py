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

Initial opinions are such that agents with the left identity have opinions [0,0.5) and agents with right identity have opinions (0.5, 1].

Experiment:
["ingroupAmbiguity" 0 0.1]
["outgroupAmbiguity" 0 0.1]
["confidenceBound" 0.2]
["uniform-initial-opinion" false]
["homophily" 0.95]
["seed" [0 1 99]]

convergenceRate 0.5
num-agents 100

Here, we visualise the degree of polarization, diversity and extremeness in a 2x2 setting (with/without ingroup ambigutiy and with/wihtout outgroup ambiguity).
"""

# %%
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

import json


def esteban_ray_index_from_df(
    opinions, identity_col="identity", opinion_col="opinion", alpha=0
):
    """
    Compute Esteban-Ray polarization index from a dataframe with group identities and opinions.

    Gestefeld recommends alpha=0
    """
    # opinions = x["final-opinions"]
    identities = ["left"] * 50 + ["right"] * 50
    op = pd.DataFrame({identity_col: identities, opinion_col: opinions})
    # compute group stats
    group_stats = op.groupby(identity_col)[opinion_col].agg(["mean", "count"])
    total = group_stats["count"].sum()
    group_stats["pop_share"] = group_stats["count"] / total

    y = group_stats["mean"].values
    pop_shares = group_stats["pop_share"].values

    # esteban-ray formula
    P = 0
    n = len(pop_shares)
    # K =  2^(1+α)  n   # see Gestefeld
    k = 0.5 * 2 ** (1 + alpha) * n
    for i in range(n):
        for j in range(n):
            P += (pop_shares[i] ** (1 + alpha)) * pop_shares[j] * abs(y[i] - y[j])

    return k * P


def parse_opinions(series):
    """Parse all 'final-opinions' rows into a 2D NumPy array efficiently."""
    parsed = series.str.replace(" ", ",", regex=False).apply(json.loads)
    arr = np.vstack(parsed.values)
    return arr  # shape = (num_rows, 100)


def calcEx(x):
    # a = json.loads(x["final-opinions"].replace(" ", ","))
    b = np.abs(np.array(x) - 0.5)
    return np.mean(b)


def calcStd(x):
    a = json.loads(x["final-opinions"].replace(" ", ","))
    b = np.std(a)
    return b


def plot_box(df, ax, hom, eps, nu_in, nu_out, out):
    mask = (
        (df["homophily"] == hom)
        & (df["confidenceBound"] == eps)
        & (df["ingroupAmbiguity"] == nu_in)
        & (df["outgroupAmbiguity"] == nu_out)
        & (df["[step]"] == 1e5)
    )
    sub = df.loc[mask].copy()
    if sub.empty:
        print("No matching data for given parameters.")
        return

    opinions = parse_opinions(sub["final-opinions"])  # shape: (n, 100)

    # Compute metrics vectorized
    if out == "polarization":
        sub["er"] = [
            esteban_ray_index_from_df(opinions[ns, :])
            for ns in range(len(opinions[:, 0]))
        ]
        data = sub[["er"]]
    elif out == "extremeness":
        sub["extremeness_all"] = np.mean(np.abs(opinions - 0.5), axis=1)
        data = sub[["extremeness_all"]]
    elif out == "standard-deviation":
        sub["std_left"] = np.std(opinions[:, :50], axis=1)
        sub["std_right"] = np.std(opinions[:, 50:], axis=1)
        sub["std_all"] = np.std(opinions, axis=1)
        combined_std = np.concatenate([sub["std_left"], sub["std_right"]])
        data = pd.DataFrame(
            {"std_combined": combined_std, "std_all": np.tile(sub["std_all"], 2)}
        )
    else:
        raise ValueError("Unknown 'out' parameter")

    # Plot
    sns.boxplot(
        data=data,
        ax=ax,
        fliersize=0,
        saturation=1,
        boxprops={"alpha": 0.2, "facecolor": "grey"},
    )
    sns.stripplot(
        data=data,
        ax=ax,
        alpha=0.8,
        color="darkgrey",
        size=1.5,
    )
    return data


# %%


df = pd.read_table(
    "sim_data/2025-11-02_ingroupXoutgroupAmbiguity_sortedInitialOps.csv",
    delimiter=",",
    skiprows=6,
)

hom = 0.95
res = []
for out in ["extremeness", "standard-deviation", "polarization"]:
    fig, axs = plt.subplots(
        2,
        2,
        sharex=True,
        sharey=True,
        figsize=((5 + ((out == "standard-deviation") * 2)) / 2.54, 7 / 2.54),
    )
    a = plot_box(df, axs[0, 0], hom, 0.2, 0.0, 0.0, out)
    b = plot_box(df, axs[0, 1], hom, 0.2, 0.1, 0.0, out)
    c = plot_box(df, axs[1, 0], hom, 0.2, 0.0, 0.1, out)
    res.append(c.reset_index().drop(columns="index"))
    d = plot_box(df, axs[1, 1], hom, 0.2, 0.1, 0.1, out)
    if out == "standard-deviation":
        axs[1, 0].set_xticklabels(["in-group    ", "    overall"])
        axs[1, 1].set_xticklabels(["in-group    ", "    overall"])
        axs[0, 0].set_xlim(-0.6, 1.6)

    else:
        axs[1, 0].set_xticklabels(["overall"], fontsize=8)
        axs[1, 1].set_xticklabels(["overall"], fontsize=8)
        axs[0, 0].set_xlim(-0.8, 0.8)

    # fig.suptitle("extremeness")
    xmax = axs[1, 0].get_xlim()[1]
    xmid = (xmax - axs[1, 0].get_xlim()[0]) / 2 + axs[1, 0].get_xlim()[0]
    axs[0, 0].set_ylim(0, 0.4)
    ymid = 0.2

    if out == "polarization":
        ymid = 0.35
        axs[0, 0].set_ylim(0, 0.7)
        # axs[0, 0].set_yticks([0, ])
    fig.text(0.5, 1, "$ingroupAmibguity$", fontsize=8, va="top", ha="center")
    axs[0, 0].text(xmid, 2 * ymid * 1.1, f"{0.0}", va="center", ha="center", fontsize=8)
    axs[0, 1].text(xmid, 2 * ymid * 1.1, f"{0.1}", va="center", ha="center", fontsize=8)
    fig.text(
        1, 0.5, "$outgroupAmibguity$", fontsize=8, va="center", ha="right", rotation=90
    )
    axs[0, 1].text(
        1.2 * xmax,
        ymid,
        f"{0.0}",
        rotation=90,
        va="center",
        ha="left",
        fontsize=8,
    )
    axs[1, 1].text(
        1.2 * xmax,
        ymid,
        f"{0.1}",
        rotation=90,
        fontsize=8,
        va="center",
        ha="left",
    )
    bbox = dict(facecolor="k", alpha=1, edgecolor="black", pad=2.5)
    axs[0, 0].set_ylabel(out, y=-0.1, fontsize=8, bbox=bbox, color="white")
    if out == "standard-deviation":
        axs[0, 0].set_ylabel("diversity", y=-0.1, fontsize=8, bbox=bbox, color="white")
    fig.tight_layout()
    plt.savefig(f"figs/expHomInOut_hom{hom}_{out}.pdf", dpi=600)
# %%
