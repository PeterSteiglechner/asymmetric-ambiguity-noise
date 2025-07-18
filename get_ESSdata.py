import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

df = pd.read_csv("~/csh-research/projects/#data/raw/ess/ESS_Austria.csv")
att = "imueclt"
df2 = df.loc[df.essround==11][[att, "prtcleat", "anweight"]]
df2[att] = df2[att].replace([66,77,88,99], np.nan)
#df2[att] = df2[att].replace([6,7,8,9], np.nan)
df2["party_feel_closest"] = df2["prtcleat"].map({
    1: "SPÖ",
    2:"ÖVP",
    3:"FPÖ",
    5:"Grüne",
    6:"KPÖ",
    7:"NEOS",
    8:"Other",
    66: "none",
    88:"none",
    77:np.nan,
    99:np.nan
    }).replace({
        "SPÖ": "middle left",
        "NEOS": "middle right",
        "Other": np.nan,
        "Grüne": "left",
        "KPÖ":"left",
        "FPÖ":"right",
        "ÖVP":"middle right",
    }
    )
df2 = df2.drop(columns=["prtcleat"])
df2["party_feel_closest"].value_counts()
df2 = df2.dropna()

df2[att].value_counts().sort_index()#.plot.hist()

# df2[att].mean()
# (df2[att] * df2["anweight"] / df2["anweight"].sum()).sum()
# df2.groupby(att)["anweight"].mean()

Likert_wrclmch = {
    1: -0.8, 
    2: -0.4,
    3: 0, 
    4: 0.4, 
    5: 0.8
}

Likert_010inv = dict(zip(np.arange(0,11), np.linspace(1,-1,12)[:11]+ np.diff(np.linspace(1,-1,12))/2))

df2[att]  =df2[att].map(Likert_010inv)# (df2[att]-1)/(5-1) * 2 - 1


#df2["party_feel_closest"] = pd.Categorical(df2["party_feel_closest"], categories=['left', 'middle left', 'none', 'middle right', 'right'])

df2["party_feel_closest"] = pd.Categorical(df2["party_feel_closest"], categories=['left', 'middle left', 'middle right', 'right'])



n_agents = 200
counts = []
for s in range(50): 
    np.random.seed(s)
    a = df2.dropna().sample(n_agents).sort_values("party_feel_closest").to_csv(f"datasets/ess11_austria_{att}_n{n_agents}_seed{s}.csv", index=False)

#     counts.append(a["party_feel_closest"].value_counts().sort_index().values)
# df2.groupby("party_feel_closest")[att].mean()



# np.array(counts).mean(axis=0)
# np.array(counts).std(axis=0)