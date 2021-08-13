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
from catboost import CatBoostRegressor
import pandas as pd
import numpy as np
from sklearn.metrics import mean_squared_error as mse
from skopt.plots import plot_convergence
import pickle

for l in range(1, 5):

    dados = criar_dataset(l)

    def treinar_modelo(params):
        iterations = params[0]
        depth = params[1]
        learning_rate = params[2]
        random_strength = params[3]
        bagging_temperature = params[4]
        border_count = params[5]
        l2_leaf_reg = params[6]
        
        print(params, '\n')

        train = dados.iloc[:240]
        test = dados.iloc[240:]

        xtr = np.array(train.drop(["y1", "y2", "y3", "y4"], axis=1))
        xts = np.array(test.drop(["y1", "y2", "y3", "y4"], axis=1))
        ytr, yts = np.array(train[f'y{l}']), np.array(test[f'y{l}'])

        mdl = CatBoostRegressor(verbose = False, 
        iterations=iterations, depth=depth, learning_rate=learning_rate, random_strength= random_strength,
        bagging_temperature=bagging_temperature, border_count=border_count, l2_leaf_reg=l2_leaf_reg)

        mdl.fit(xtr, ytr)
        p = mdl.predict(xts)

        return mse(yts, p)

    space = [(10, 300), # iterations
            (1, 8), # depth
            (0.01, 1.0), # learning_rate
            (1e-9, 10), # random_strength
            (0.0, 1.0), # bagging_temperature
            (1, 255), # border_count
            (2, 30), # l2_leaf_reg
            ] 

    resultados_gp = gp_minimize(treinar_modelo, space, random_state=1, verbose=1, n_calls=300, n_random_starts=10)

    # plot convergence 
    plot = plot_convergence(resultados_gp)
    fig = plot.get_figure()
    fig.savefig(f"../plots/plots_convergence/mdl_ipca_cb_y{l}.png")
    fig.clear()

    # saved pickle model
    mdl = CatBoostRegressor(iterations = resultados_gp.x[0], depth = resultados_gp.x[1], learning_rate = resultados_gp.x[2],
                random_strength = resultados_gp.x[3], bagging_temperature = resultados_gp.x[4], border_count = resultados_gp.x[5], l2_leaf_reg = resultados_gp.x[6])

    pkl_filename = f"../models/saved/mdl_ipca_cb_y{l}.pkl"
    with open(pkl_filename, 'wb') as file:
        pickle.dump(mdl, file)

