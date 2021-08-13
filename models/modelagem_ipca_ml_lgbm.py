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
from lightgbm import LGBMRegressor
import pandas as pd
import numpy as np
from sklearn.metrics import mean_squared_error as mse
from skopt.plots import plot_convergence
import pickle

for l in range(1, 5):

    dados = criar_dataset(l)

    def treinar_modelo(params):
        learning_rate = params[0]
        num_leaves = params[1]
        min_child_samples = params[2]
        subsample = params[3]
        colsample_bytree = params[4]
        feature_fraction = params[5]
        bagging_fraction = params[6]
        max_depth = params[7]
        min_split_gain = params[8]
        min_child_weight = params[9]
        
        print(params, '\n')

        train = dados.iloc[0:240]
        test = dados.iloc[240:]

        xtr = np.array(train.drop(["y1", "y2", "y3", "y4"], axis=1)), 
        xts = np.array(test.drop(["y1", "y2", "y3", "y4"], axis=1))
        ytr, yts = np.array(train[f'y{l}']), np.array(test[f'y{l}'])


        mdl = LGBMRegressor(learning_rate=learning_rate, num_leaves=num_leaves, min_child_samples=min_child_samples,
                        subsample=subsample, colsample_bytree=colsample_bytree, feature_fraction=feature_fraction, 
                        bagging_fraction=bagging_fraction, max_depth=max_depth, min_split_gain=min_split_gain, 
                        min_child_weight=min_child_weight, random_state=0, subsample_freq=1, n_estimators=100)
        
        mdl.fit(xtr, ytr)
        p = mdl.predict(xts)

        return mse(yts, p)


    space = [(1e-3, 1e-1, 'log-uniform'), #learning_rate
            (2, 128), # num_leaves
            (1, 100), # min_child_samples
            (0.05, 1.0), # subsamples
            (0.1, 1.0), # colsample_bytree
            (0.1, 0.9), # feature_fraction
            (0.8, 1), # bagging_fraction 
            (17, 25), # max_depth
            (0.001, 0.1), # min_split_gain
            (10, 25) # min_child_weight
            ] 

    resultados_gp = gp_minimize(treinar_modelo, space, random_state=1, verbose=1, n_calls=300, n_random_starts=10)

    # plot convergence 
    plot = plot_convergence(resultados_gp)
    fig = plot.get_figure()
    fig.savefig(f"../plots/plots_convergence/mdl_ipca_lgbm_y{l}.png")
    fig.clear()

    # saved pickle model
    mdl = LGBMRegressor(learning_rate=resultados_gp.x[0], num_leaves=resultados_gp.x[1], min_child_samples=resultados_gp.x[2],
                    subsample=resultados_gp.x[3], colsample_bytree=resultados_gp.x[4], feature_fraction=resultados_gp.x[5],
                    bagging_fraction=resultados_gp.x[6], max_depth=resultados_gp.x[7], min_split_gain=resultados_gp.x[8], min_child_weight=resultados_gp.x[9],
                    random_state=0, subsample_freq=1, n_estimators=100)

    pkl_filename = f"../models/saved/mdl_ipca_lgbm_y{l}.pkl"
    with open(pkl_filename, 'wb') as file:
        pickle.dump(mdl, file)
