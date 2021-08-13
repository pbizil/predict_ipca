# %%

import sqlite3
import pandas as pd
import numpy as np
import pickle
import shap
import matplotlib.pyplot as plt

def criar_dataset(layer):
    conn = sqlite3.connect("../data/app_db.db")
    dados = pd.read_sql("select * from dados", conn)

    dados["y1"] = dados["ipca"].shift(-1)
    dados["y2"] = dados["ipca"].shift(-2)
    dados["y3"] = dados["ipca"].shift(-3)
    dados["y4"] = dados["ipca"].shift(-4)

    l_cols = ["ipca", "inpc", "igpm"]

    for i in l_cols:
        dados[i + "shift"] = dados[i].shift(1)

    for i in dados.drop(["y1", "y2", "y3", "y4"], axis=1).columns:
        dados[i] = dados[i].fillna(-999999999999)

    dados = dados.set_index("date")
    dados = dados.dropna(subset=[f"y{layer}"])

    return dados

conn = sqlite3.connect("../data/app_db.db")

for l in [1, 2, 3, 4]:
    dados = criar_dataset(l)
    preds = dados[[f"y{l}", f"ipca_mean_{l}"]].iloc[240:]
    train = dados.iloc[:240]
    test = dados.iloc[240:]
    xtr, xts = np.array(train.drop(["y1", "y2", "y3", "y4"], axis=1)), np.array(test.drop(["y1", "y2", "y3", "y4"], axis=1))
    ytr, yts = np.array(train[f'y{l}']), np.array(test[f'y{l}'])

    for i in ["cb", "xg", "lgbm"]:
        mdl = pickle.load(open(f"../models/saved/mdl_ipca_{i}_y{l}.pkl", 'rb'))
        mdl.fit(xtr, ytr)
        preds[f"y_preds_{i}_{l}"] = mdl.predict(xts)

        mdl = pickle.load(open(f"../models/saved/mdl_ipca_{i}_y{l}.pkl", 'rb'))
        mdl.fit(train.drop(["y1", "y2", "y3", "y4"], axis=1), train[f'y{l}'])
        explainer = shap.TreeExplainer(mdl)
        shap_values = explainer(train.drop(["y1", "y2", "y3", "y4"], axis=1))
        shap.plots.bar(shap_values, show=False)
        plt.title(f'Importância das variáveis para predição - {i} para {l}')
        plt.savefig(f"../plots/plots_explain/mdl_explain_{i}_{l}.png", dpi=300, bbox_inches = "tight")
        plt.close()

    preds.to_sql(f"preds_l{l}", conn, if_exists="replace")




# %%

from sklearn.metrics import mean_squared_error as mse

print("Erro quadrático médio das expectativas de mercado: ", mse(preds[f"y{l}"], preds[f"ipca_mean_{l}"]))
print("Erro quadrático médio do modelo catboost: ", mse(preds[f"y{l}"], preds[f"y_preds_cb_{l}"]))
print("Erro quadrático médio do modelo xgboost: ", mse(preds[f"y{l}"], preds[f"y_preds_xg_{l}"]))
print("Erro quadrático médio do modelo lgbm: ", mse(preds[f"y{l}"], preds[f"y_preds_lgbm_{l}"]))

# %%

import sqlite3
import pandas as pd
import numpy as np
import pickle
import shap
import matplotlib.pyplot as plt


l = 1
i = "cb"
dados = criar_dataset(l)
train = dados.iloc[:240]
mdl = pickle.load(open(f"../models/saved/mdl_ipca_{i}_y{l}.pkl", 'rb'))
mdl.fit(train.drop(["y1", "y2", "y3", "y4", "y5", "y6"], axis=1), train[f'y{l}'])
explainer = shap.TreeExplainer(mdl)
shap_values = explainer(train.drop(["y1", "y2", "y3", "y4", "y5", "y6"], axis=1))
shap.plots.bar(shap_values, show=False)
plt.savefig(f"../plots/mdl_explain_{i}_{l}.png", dpi=300, bbox_inches = "tight")
plt.close()

# %%

train



# %%



