import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

df = pd.read_csv("~/csh-research/projects/#data/raw/ess/ESS_Austria.csv")
att = "imueclt"
df2 = df.loc[df.essround == 11][[att, "prtcleat", "anweight"]]
df2[att] = df2[att].replace([66, 77, 88, 99], np.nan)
# df2[att] = df2[att].replace([6,7,8,9], np.nan)
df2["party_feel_closest"] = (
    df2["prtcleat"]
    .map(
        {
            1: "SPÖ",
            2: "ÖVP",
            3: "FPÖ",
            5: "Grüne",
            6: "KPÖ",
            7: "NEOS",
            8: "Other",
            66: "none",
            88: "none",
            77: np.nan,
            99: np.nan,
        }
    )
    .replace(
        {
            "SPÖ": "middle left",
            "NEOS": "middle right",
            "Other": np.nan,
            "Grüne": "left",
            "KPÖ": "left",
            "FPÖ": "right",
            "ÖVP": "middle right",
        }
    )
)
df2 = df2.drop(columns=["prtcleat"])
df2["party_feel_closest"].value_counts()
df2 = df2.dropna()

df2[att].value_counts().sort_index()  # .plot.hist()

# df2[att].mean()
# (df2[att] * df2["anweight"] / df2["anweight"].sum()).sum()
# df2.groupby(att)["anweight"].mean()

Likert_wrclmch = {1: -0.8, 2: -0.4, 3: 0, 4: 0.4, 5: 0.8}

Likert_010inv = dict(
    zip(
        np.arange(0, 11),
        np.linspace(1, -1, 12)[:11] + np.diff(np.linspace(1, -1, 12)) / 2,
    )
)

df2[att] = df2[att].map(Likert_010inv)  # (df2[att]-1)/(5-1) * 2 - 1


# df2["party_feel_closest"] = pd.Categorical(df2["party_feel_closest"], categories=['left', 'middle left', 'none', 'middle right', 'right'])

df2["party_feel_closest"] = pd.Categorical(
    df2["party_feel_closest"],
    categories=["left", "middle left", "middle right", "right"],
)


n_agents = 200
counts = []
all_samples = []
for s in range(50):
    np.random.seed(s)
    a = df2.dropna().sample(n_agents).sort_values("party_feel_closest")
    a.to_csv(f"datasets/ess11_austria_{att}_n{n_agents}_seed{s}.csv", index=False)
    all_samples.append(a)

#     counts.append(a["party_feel_closest"].value_counts().sort_index().values)
# df2.groupby("party_feel_closest")[att].mean()


# np.array(counts).mean(axis=0)
# np.array(counts).std(axis=0)


# %%
import seaborn as sns
import matplotlib.pyplot as plt


bins = np.sort(a["imueclt"].unique())

for n, a in enumerate(all_samples):
    sns.histplot(
        a,
        hue="party_feel_closest",
        x="imueclt",
        multiple="dodge",
        ax=ax,
        bins=bins,
        legend=(n == 0),
        shrink=0.8,
        alpha=0.2,
    )
leg = ax.get_legend()
leg.set_title("")
# %%


# %%

import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

smallfs = 7
bigfs = 10
plt.rcParams.update({"font.size": smallfs})

# Bin edges
bins = np.linspace(-1, 1, 12)

# Collect histogram results across samples
records = []

for df in all_samples:
    df = df.copy()
    df["bin"] = pd.cut(df["imueclt"], bins=bins, include_lowest=True)
    counts = df.groupby(["bin", "party_feel_closest"]).size().reset_index(name="count")
    records.append(counts)

# Concatenate and label which sample it came from (optional but useful for bootstrap)
for i, r in enumerate(records):
    r["sample"] = i
data = pd.concat(records, ignore_index=True)
data["bin_mid"] = data["bin"].apply(lambda x: x.mid)
# Optional: convert bin to string for bette

fig = plt.figure(figsize=(12 / 2.54, 6 / 2.54))
ax = plt.axes()
sns.barplot(
    data=data,
    x="bin_mid",
    y="count",
    hue="party_feel_closest",
    estimator=np.mean,
    color="darkgrey",
    edgecolor="white",
    errorbar="sd",  # standard deviation; or use "ci" for 95% CI
    errwidth=1,
    capsize=0.3,
    ax=ax,
    legend=False,
)

ax.set_xticklabels([f"{(10-n):.0f}" for n, x in enumerate(data["bin_mid"].unique())])
ax2 = ax.twiny()
ax2.set_xticks(ax.get_xticks())
ax2.set_xlim(ax.get_xlim())
ax2.set_xticklabels(
    [f"{x:.2f}" for n, x in enumerate(data["bin_mid"].unique())],
)

ax.set_xlabel(
    "\n"
    + r"$imueclt$"
    + r": `Country's cultural life undermined or enriched by immigrants?'"
)
ax.text(-0.25, -5, "enriched", fontsize=smallfs, ha="left")
ax.text(10.25, -5, "undermined", fontsize=smallfs, ha="right")
ax.set_ylabel("Mean count")
plt.tight_layout()
# ax.legend(title="", ncol=2)
ax.set_ylim(
    0,
)
for i, name in enumerate(a["party_feel_closest"].unique()):
    arrowprops = dict(
        arrowstyle="->",
        color="grey",
        connectionstyle="angle,angleA=0,angleB=-90,rad=10",
    )
    m = data.loc[
        (data.bin_mid == data.bin_mid.max()) & (data.party_feel_closest == name),
        "count",
    ].mean()
    s = data.loc[
        (data.bin_mid == data.bin_mid.max()) & (data.party_feel_closest == name),
        "count",
    ].std()
    ax.annotate(
        name,
        (10 - 0.5 + (i + 1) * 0.2, m + s + 1),
        (8.8 + 0.2 * i, 17 + i * 2),
        arrowprops=arrowprops,
        ha="right",
        va="center",
        color="grey",
    )

# %%
