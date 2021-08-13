# %%

import sqlite3
import pandas as pd


def criar_dataset(lag):
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
    dados = dados.dropna(subset=[f"y{lag}"])

    return dados


# %%

from skopt import gp_minimize
from xgboost import XGBRegressor
import pandas as pd
import numpy as np
from sklearn.metrics import mean_squared_error as mse
from skopt.plots import plot_convergence
import pickle

for l in range(1, 5):

    dados = criar_dataset(l)

    def treinar_modelo(params):
        colsample_bylevel = params[0]
        colsample_bytree = params[1]
        gamma = params[2]
        learning_rate = params[3]
        max_delta_step = params[4]
        max_depth = params[5]
        
        print(params, '\n')

        train = dados.iloc[:240]
        test = dados.iloc[240:]

        xtr = np.array(train.drop(["y1", "y2", "y3", "y4"], axis=1))
        xts = np.array(test.drop(["y1", "y2", "y3", "y4"], axis=1))
        ytr, yts = np.array(train[f'y{l}'])
        yts = np.array(test[f'y{l}'])

        mdl = XGBRegressor(colsample_bylevel = colsample_bylevel, colsample_bytree = colsample_bytree, gamma = gamma,
                        learning_rate = learning_rate, max_delta_step = max_delta_step, max_depth = max_depth)

        mdl.fit(xtr, ytr)
        p = mdl.predict(xts)

        return mse(yts, p)

    space = [(0.6, 0.7), # colsample_bylevel
            (0.6, 0.7), # colsample_bytree
            (0.01, 1), # gamma
            (0.0001, 1), # learning_rate
            (0.1, 10), # max_delta_step
            (6, 15), # max_depth
            ] 

    resultados_gp = gp_minimize(treinar_modelo, space, random_state=1, verbose=1, n_calls=300, n_random_starts=10)

    plot = plot_convergence(resultados_gp)
    fig = plot.get_figure()
    fig.savefig(f"../plots/plots_convergence/mdl_ipca_xg_y{l}.png")
    fig.clear()

    # saved pickle model
    mdl = XGBRegressor(colsample_bylevel = resultados_gp.x[0], colsample_bytree = resultados_gp.x[1], gamma = resultados_gp.x[2],
                learning_rate = resultados_gp.x[3], max_delta_step = resultados_gp.x[4], max_depth = resultados_gp.x[5])

    pkl_filename = f"../models/saved/mdl_ipca_xg_y{l}.pkl"
    with open(pkl_filename, 'wb') as file:
        pickle.dump(mdl, file)


