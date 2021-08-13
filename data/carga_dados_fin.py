
import pandas as pd
from tqdm import tqdm
import sqlite3
import requests

num_series_bacen_m = {"index_exp_futuras": 4395, "index_confianca": 4393,
"index_cond_econ_atuais": 4394, "ibc_br": 24363, "nfsp_rp": 4649, "ipca_comerc": 4447,"ipca_nao_comerc": 4448,
"ipca_itens_livres": 11428, "ipca_servicos": 10844, "ipca_duraveis": 10843, "ipca_bens_semidur": 10842,
"ipca_nao_duraveis": 10841, "inpc_index_dif": 21379, "inpc_nucleo_suav": 4466, "igpm": 189, "igpm_di": 190,
"ipc_br": 191, "incc": 192, "ipa": 225, "ipc_nucleo": 4467, "igp10": 7447, "igpm_1decendio": 7448, "igpm_2decendio": 7449,
"ipam": 7450, "ipam_1decendio": 7451, "ipam_2decendio": 7452, "ipcm": 7453, "ipcm_1decendio": 7454, "ipcm_2decendio": 7455,
"incc": 7456, "incc_1decendio": 7457, "incc_2decendio": 7458, "ipaog_prod_indus": 7459, "ipaog_prod_agro": 7460,
"inpc": 188, "ipc_fipe": 193, "ipc_fipe_2quadrisemana": 272, "ipca": 433, "ipca_alim_beb": 1635, "ipca_habit": 1636,
"ipca_art_habit": 1637, "ipca_vestuario": 1638, "ipca_transportes": 1639, "ipca_comunicacao": 1640, "ipca_saude": 1641,
"ipca_desp_pes": 1642, "ipca_educacao": 1643, "inpc_alim_beb": 1644, "inpc_habit": 1645, "inpc_art_habit": 1646,
"inpc_vestuario": 1647, "inpc_transporte": 1648, "inpc_comunicacao": 1649, "inpc_saude": 1650, "inpc_desp_pes": 1651, 
"inpc_educacao": 1652, "ipca_monitorados": 4449, "ipc_fipe_1quadrisemana": 7463, "ipc_fipe_3quadrisemana": 7464,
"ipc_fipe_aliment": 7465, "ipc_fipe_indust": 7467, "ipc_fipe_innatura": 7468, "ipc_fipe_habit": 7469,
"ipc_fipe_transp": 7470, "ipc_fipe_desp_pes": 7471, "ipc_fipe_vest": 7472, "ipc_fipe_saude": 7473,
"ipc_fipe_educacao": 7474, "ipc_fipe_comerc": 7475, "ipc_fipe_nao_comerc": 7476, "ipc_fipe_monit": 7477,
"ipca15": 7478, "ipca_e": 10764, "ipca_12meses": 13522, "ipca_industriais": 27863, "ipca_alim_dom": 27864,
"custo_cesta_aracaju": 7479, "custo_cesta_belem": 7480, "custo_cesta_bh": 7481, "custo_cesta_brasilia": 7482,
"custo_cesta_curitiba": 7483, "custo_cesta_floripa": 7484, "custo_cesta_fortaleza": 7485, "custo_cesta_goiania": 7486,
"custo_cesta_jp": 7487, "custo_cesta_natal": 7488, "custo_cesta_poa": 7489, "custo_cesta_recife": 7490,
"custo_cesta_rj": 7491, "custo_cesta_salvador": 7492, "custo_cesta_sp": 7493, "custo_cesta_vitoria": 7494,
"pib_acum_12meses": 4192, "pib_mensal": 4380, "pib_acum_ult12meses": 4382}

num_series_bacen_d = {"selic_diaria": 11, "selic_acum": 1178, "meta_selic": 432}


def carga_dados_historicos(mes, ano, n_serie_m, n_serie_d):
    
    database = pd.DataFrame(index = pd.PeriodIndex(pd.date_range(start='1995-1-1', end=f'{ano}-{mes}-01', freq='M'), freq="M"))

    for i in tqdm(n_serie_m.keys(), desc="Carga de dados mensais"):
        n = num_series_bacen_m[i]
        data = pd.read_json(f"https://api.bcb.gov.br/dados/serie/bcdata.sgs.{n}/dados?formato=json&dataInicial=01/01/1995&dataFinal=01/{mes}/{ano}")
        data = data.set_index(pd.PeriodIndex(pd.to_datetime(data["data"], format='%d/%m/%Y'), freq="M")).drop(["data"], axis=1)
        database[i] = data["valor"]

    for i in tqdm(n_serie_d.keys(), desc="Carga de dados diários"):
        n = num_series_bacen_d[i]
        data = pd.read_json(f"https://api.bcb.gov.br/dados/serie/bcdata.sgs.{n}/dados?formato=json&dataInicial=01/01/1995&dataFinal=11/{mes}/{ano}")
        data["data"] = pd.to_datetime(data["data"], format='%d/%m/%Y')
        data = data.set_index('data').resample('M').mean().reset_index()
        data = data.set_index(pd.PeriodIndex(data["data"], freq="M")).drop(["data"], axis=1)
        database[i] = data["valor"]

    database = database.reset_index()
    database["index"] = database["index"].astype(str)
    database = database.rename(columns={"index": "date"})
    
    conn = sqlite3.connect("data/app_db.db")
    database.to_sql(name="dados", con = conn, if_exists='replace')

    return database


def carga_dados_expectativas(mes, ano):
    conn = sqlite3.connect("../data/app_db.db")
    database = pd.read_sql("select * from dados", conn)
    database = database.set_index(["date"])
    dics = {'IGP-DI': 'igp_di', 'IGP-M': 'igp_m', 'INPC': 'inpc','IPCA': 'ipca'}
    periodo = pd.date_range(start='2000-01-01', end=f'{ano}-{mes}-01', freq='M')

    for d in dics.values():
        for l in range(1, 6):
            database[d + '_mean_' + str(l)] = None
            database[d + '_median_' + str(l)] = None
            database[d + '_dp_' + str(l)] = None

    for i in dics.keys():

        for o in tqdm(range(periodo.shape[0]), desc=i):
            
            try:
            
                d = periodo[o].strftime('%Y-%m-%d')

                for n in range(1, 6):
                    ds = pd.date_range(start = d, periods=6, freq='M')[n].strftime('%Y-%m')
                    y = ds.split('-')[0]
                    m = ds.split("-")[1]

                    r = requests.get(f"https://olinda.bcb.gov.br/olinda/servico/Expectativas/versao/v1/odata/ExpectativaMercadoMensais?$top=1" +
                    "&$filter=Indicador%20eq%20'{i}'%20and%20DataReferencia%20eq%20'{m}%2F{y}'%20and%20Data%20le%20'{d}'&$orderby=Data%20desc&$" +
                    "format=json&$select=Indicador,Data,DataReferencia,Media,Mediana,DesvioPadrao,CoeficienteVariacao,Minimo,Maximo")

                    x = d.split('-')[0] + '-' + d.split('-')[1]
                    data = pd.DataFrame(r.json()["value"])
                    database[dics[i] + '_mean_' + str(n)].loc[x] = data.loc[0]['Media']
                    database[dics[i] + '_median_' + str(n)].loc[x] = data.loc[0]['Mediana']
                    database[dics[i] + '_dp_' + str(n)].loc[x] = data.loc[0]['DesvioPadrao']

            except:
                pass

    database = database.drop("index", 1)
    database = database.reset_index()
    database["date"] = database["date"].astype(str)
    conn = sqlite3.connect("../data/app_db.db")
    database.to_sql(name="dados", con = conn, if_exists='replace', index=False)

    return database


if __name__ == '__main__':
    carga_dados_historicos(7, 2021, num_series_bacen_m, num_series_bacen_d)
    carga_dados_expectativas(7, 2021)