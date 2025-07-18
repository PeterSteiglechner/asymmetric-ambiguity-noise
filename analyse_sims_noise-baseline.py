import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns 

res_all = {}
for noise in ["ambiguity", "adaptation", "selectivity"]:
    fname = f"2025-07-17_baseline_bias-vs-{noise}-noise"
    df = pd.read_csv(f"sim_data/{fname}.csv", skiprows=6)

    params = ['identity-dependent-noise','sigma-ambiguity-within-group', 'sigma-ambiguity', 'confidence-bound', 'learning-rate','prob-exogenous', 'sigma-selectivity', 'sigma-exogenous', 'sigma-selectivity-within-group', 'sigma-adaptation',       'sigma-adaptation-within-group', 'homophily', 'seed']

    meta_data = df.loc[df["[run number]"].isin(params)].dropna(axis="columns").T.iloc[1:]
    meta_data.columns = params
    meta_data["identity-dependent-noise"] = meta_data["identity-dependent-noise"].replace({"false": False, "true": True}).astype(bool)

    output = df.iloc[len(params), 1:].unique()
    other_reporters = ["reporter", "final", "min", "max", "mean"]


    all_runs = []
    vals = df.iloc[(len(params)+len(other_reporters)+1 ) :  len(df)][1:-1]
    for i in meta_data.index:
        v = vals[[a for a in vals.columns if a.split(".")[0]==str(i)]] 
        v.columns = output
        v.loc[:, ["run"]] = i
        for p in params:
            if p == "fname":
                seed =  meta_data.loc[str(i)][p].split(".")[0][-1]
                v.loc[:, ["seed"]] = seed
            else:
                v.loc[:, [p]] = meta_data.loc[str(i)][p]
        all_runs.append(v)
    res = pd.concat(all_runs)

    outSC = [
    "step",
    'std_all',
    'mean_all',
    'extr_all',
    'std_right',
    'std_middleright',
    'std_middleleft',
    'std_left',
    'mean_right',
    'mean_middleright',
    'mean_middleleft',
    'mean_left',
    'extr_right',
    'extr_middleright',
    'extr_middleleft',
    'extr_left',
    ]

    paramsSC = [
        "identity-switch",
        "sig_am_in",
        "sig_am",
        "eps",
        "mu",
        "p_ex",
        "sig_se",
        "sig_ex",
        "sig_se_in",
        "sig_ad",
        "sig_ad_in",
        "hom",
        "seed"
    ]

    res = res.rename(columns=dict(zip(output, outSC)))
    res = res.rename(columns=dict(zip(params, paramsSC)))

    res = res.astype(float)

    res.to_csv(f"sim_data/{fname}_processed.csv")
    res_all[noise] = res

#%%
#################################
#####  Analyse   #####
#################################
T = 1e5
smallfs = 7
bigfs =10
plt.rcParams.update({"font.size":bigfs})
#%%
fig, axs = plt.subplots(2, 4, sharex=False, sharey=False, gridspec_kw={"width_ratios":[1, 1, 1, 0.05]}, figsize=(19/2.54, 12/2.54))
for n, (out, vmax, outName) in enumerate(zip(["extr_all", "std_all"], [0.4, 0.6], [r"Extremeness $E$", r"Diversity $D$"])):
    for ax, noise_type, noiseName in zip(axs[n, :-1][::-1], ["se", "ad", "am"], ["selectivityNoise", "adaptationNoise", "ambiguityNoise"]):
        res = res_all[noiseName.split("Noise")[0]]
        if ax!=axs[n, 0]:
            ax.sharex(axs[n, 0])
            #ax.sharey(axs[n, 0])
        if n==0:
            ax.set_title(rf"{noiseName.split("Noise")[0]}")
        dftable = res.loc[(res.step==T) & (res.hom==0.0)].pivot_table(index="eps", columns="sig_"+noise_type, values=out, aggfunc="mean").sort_index()#[::-1]
        ax.set_xlabel(rf"${noiseName}$")
        print(noise_type, out, dftable.max().max())
        sns.heatmap(dftable, cmap="Greys", annot=False, vmin=0., vmax=vmax, ax=ax, cbar=(ax==axs[n, 0]) , cbar_ax=axs[n, -1], cbar_kws={"shrink":0.36, "label":outName})
        #ax.set_aspect("equal")
        ax.set_xticks(ax.get_xticks()[1::2], minor=True)
        ax.set_xticks(ax.get_xticks()[0::2], minor=False)
        ax.set_xticklabels(ax.get_xticklabels(), rotation=0)
        if n==0: 
            ax.set_xticklabels([])
            ax.set_xlabel("")
        else:
            ax.set_xlabel(rf"${noiseName}$", x=.4)
            ax.text(1.0, -0.14, "high\nnoise", va="top", ha="right", transform=ax.transAxes, fontsize=smallfs)

        if ax!= axs[n, 0]:
            ax.set_ylabel("")
            ax.set_yticklabels([])
        else:
            ax.set_ylabel(r"$confidenceBound$")
            ax.text(-.135, 1.0, "high bias", va="bottom", ha="center", transform=ax.transAxes, fontsize=smallfs)
        
        #yticks = [0.2,0.3,0.4,0.5,0.6]
        #ax.set_yticks()
#fig.suptitle("standard deviation (all)")
fig.tight_layout()


# %%
res_all["adaptation"]

# %%
