library(DBI)
library(ggplot2)
library(rjson)
library(anytime)
library(naniar)
library(DataCombine)
library(splusTimeSeries)
library(tfplot)

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/sef_predict/data/app_db.db")
dados <- dbReadTable(con, "dados")
row.names(dados) <- dados[,"date"]

# view missing values

vis_miss(dados[0:30])

# import dados IPCA de 1980

json_file <- "https://api.bcb.gov.br/dados/serie/bcdata.sgs.433/dados?formato=json"
dados_ipca <- data.frame(do.call("rbind", fromJSON(file=json_file)))
dados_ipca$valor <- as.numeric(dados_ipca$valor)
dados_ipca$data <- as.Date(strptime(dados_ipca$data, "%d/%m/%Y"))

png(filename="~/Desktop/tcc_pos/plots/ipca_serie_completa.png")
ggplot(data = dados_ipca, aes(x=data, y=valor)) +
  geom_line(color = "#00AFBB") + 
  labs(title = "Variação mensal do IPCA - jan/1980 a jun/2021", x = "Meses", y = "Variação percentual") +
  geom_vline(xintercept = dados_ipca$data[181], color = "red", size=0.5) +
  geom_text(aes(x=dados_ipca$data[181], label="\njan/1995", y=50), colour="red", angle=90, text=element_text(size=13))

dev.off()


# import dados IPCA de 1995

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/sef_predict/data/app_db.db")
dados <- dbReadTable(con, "dados")
ipca <- dados[, c("date", "ipca")]
ipca$date <- as.Date(strptime(anytime::anydate(ipca$date), "%Y-%m-%d"))

png(filename="~/Desktop/tcc_pos/plots/ipca_serie_target.png")
ggplot(data = ipca, aes(x=date, y=ipca)) +
  geom_line(color = "#00AFBB") + 
  labs(title = "Variação mensal do IPCA - jan/1995 a jun/2021", x = "Meses", y = "Variação percentual") 

dev.off()

# analise dados de expectativas 

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/sef_predict/data/app_db.db")
dados <- dbReadTable(con, "dados")
exp_dados <- DropNA(dados, Var="ipca_mean_1")
exp_dados <-  exp_dados[, c("date", "ipca", "igpm", "inpc","ipca_mean_1", "inpc_mean_1", "igp_m_mean_1")]
exp_dados[, c("ipca")] <- shift(exp_dados[, c("ipca")], 1)
exp_dados[, c("inpc")] <- shift(exp_dados[, c("inpc")], 1)
exp_dados[, c("igpm")] <- shift(exp_dados[, c("igpm")], 1)
exp_dados$date <- as.Date(strptime(anytime::anydate(exp_dados$date), "%Y-%m-%d"))

ggplot(data = exp_dados, aes(x=date, y=ipca)) +
  geom_line(data = exp_dados, aes(x=date, y=ipca, colour = "IPCA Mensal")) +
  geom_line(data = exp_dados, aes(x=date, y=ipca_mean_1, colour = "Expectativas IPCA")) + 
  labs(title = "Variação mensal do IPCA - jan/1995 a jun/2021", x = "Meses", y = "Variação percentual") 


# amostragem

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/sef_predict/data/app_db.db")
dados <- dbReadTable(con, "dados")
ipca <- dados[, c("date", "ipca")]
ipca$date <- as.Date(strptime(anytime::anydate(ipca$date), "%Y-%m-%d"))

png(filename="~/Desktop/tcc_pos/plots/ipca_amostragem.png")
ggplot(data = ipca, aes(x=date, y=ipca)) +
  geom_line(color = "#00AFBB") + 
  labs(title = "Amostragem - Dados IPCA jan/1995 a jun/2021", x = "Meses", y = "Variação percentual") +
  geom_vline(xintercept = ipca$date[241], color = "red", size=0.5) +
  annotate("text", x=ipca$date[210], y=2, label= "treino", size = 6) +
  annotate("text", x=ipca$date[270], y=2, label= "teste", size = 6)
dev.off()


# analise principais indices de inflacao

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/sef_predict/data/app_db.db")
dados <- dbReadTable(con, "dados")
dados$date <- as.Date(strptime(anytime::anydate(ipca$date), "%Y-%m-%d"))
dados_princ_index <- dados[,c("date", "ipca" ,"inpc" , "igpm", "ipc_fipe", "ipa", "ipcm")]

colors <- c("ipca" = "#BC8F8F", "inpc" = "#9370DB", "igpm" = "#DB7093", "ipc_fipe" = "#FFD700",
            "ipa" = "#B0E0E6", "ipcm" = "#9ACD32")

png(filename="~/Desktop/tcc_pos/plots/plot_aed/index_inflacao.png")
ggplot() +
  geom_line(data = dados_princ_index, aes(x=date, y=ipca, color = "ipca")) + 
  geom_line(data = dados_princ_index, aes(x=date, y=inpc, color = "inpc")) +
  geom_line(data = dados_princ_index, aes(x=date, y=igpm, color = "igpm")) +
  geom_line(data = dados_princ_index, aes(x=date, y=ipc_fipe, color = "ipc_fipe")) +
  geom_line(data = dados_princ_index, aes(x=date, y=ipa, color = "ipa")) +
  geom_line(data = dados_princ_index, aes(x=date, y=ipcm, color = "ipcm")) +
  theme(legend.position='bottom') +
  labs(title = "Séries dos principais índices de inflação", x = "Meses", y = "Variação percentual", color = "Índices") +
  scale_colour_manual(values = colors) + 
  theme(legend.position='bottom')
dev.off()

png(filename="~/Desktop/tcc_pos/plots/plot_aed/corr_matrix_index_inflacao.png")
M = cor(dados_princ_index[,c("ipca" ,"inpc" , "igpm", "ipc_fipe", "ipa", "ipcm")])
corrplot(M, method = 'number')
dev.off()



# analise desagregada ipca 

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/sef_predict/data/app_db.db")
dados <- dbReadTable(con, "dados")
dados$date <- as.Date(strptime(anytime::anydate(ipca$date), "%Y-%m-%d"))

list_ipca_des = c("ipca", "ipca_alim_beb", "ipca_habit", "ipca_art_habit", "ipca_vestuario",
                  "ipca_transportes", "ipca_comunicacao", "ipca_saude", "ipca_desp_pes", 
                  "ipca_educacao", "ipca_e")

dados_ipca_des <- data.frame("nome" = NA, "valor" = NA)

for (i in list_ipca_des) {
  d <- data.frame("nome" = i, "valor" = dados[, c(i)])
  dados_ipca_des <- rbind(dados_ipca_des, d)
}

dados_ipca_des <- DropNA(dados_ipca_des)

png(filename="~/Desktop/tcc_pos/plots/plot_aed/analise_des_ipca.png")
ggplot() +
  geom_violin(data = data.frame(dados_ipca_des[dados_ipca_des["nome"]!="ipca",]), aes(x=nome, y=valor))  +
  geom_violin(data = data.frame(dados_ipca_des[dados_ipca_des["nome"]=="ipca",]), aes(x = nome, y = valor), fill="#836FFF")  +
  ggtitle("Distribuição das variáveis do IPCA") +
  xlab("") +
  ylab("Variação percentual") + 
  coord_flip()
dev.off()

# analise desagregada do inpc

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/sef_predict/data/app_db.db")
dados <- dbReadTable(con, "dados")
dados$date <- as.Date(strptime(anytime::anydate(ipca$date), "%Y-%m-%d"))

list_inpc_des = c("inpc", "inpc_alim_beb", "inpc_habit", "inpc_art_habit", 
             "inpc_vestuario", "inpc_transporte", "inpc_comunicacao",
             "inpc_saude", "inpc_desp_pes", "inpc_educacao")

dados_inpc_des <- data.frame("nome" = NA, "valor" = NA)

for (i in list_inpc_des) {
  d <- data.frame("nome" = i, "valor" = dados[, c(i)])
  dados_inpc_des <- rbind(dados_inpc_des, d)
}

dados_inpc_des <- DropNA(dados_inpc_des)

png(filename="~/Desktop/tcc_pos/plots/plot_aed/analise_des_inpc.png")
ggplot() +
  geom_violin(data = data.frame(dados_inpc_des[dados_inpc_des["nome"]!="inpc",]), aes(x=nome, y=valor))  +
  geom_violin(data = data.frame(dados_inpc_des[dados_inpc_des["nome"]=="inpc",]), aes(x = nome, y = valor), fill="#90EE90") +
  ggtitle("Distribuição das variáveis do INPC") +
  xlab("") +
  ylab("Variação percentual") + 
  coord_flip()
dev.off()

# analise desagregaa do ipc_fipe

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/sef_predict/data/app_db.db")
dados <- dbReadTable(con, "dados")
dados$date <- as.Date(strptime(anytime::anydate(ipca$date), "%Y-%m-%d"))
dados_ipc_fipe_des <- dados[,c("date", "ipc","ipc_fipe_aliment", "ipc_fipe_indust", "ipc_fipe_innatura", "ipc_fipe_habit", "ipc_fipe_transp", "ipc_fipe_desp_pes",              
                            "ipc_fipe_vest", "ipc_fipe_saude", "ipc_fipe_educacao", "ipc_fipe_comerc", "ipc_fipe_nao_comerc", "ipc_fipe_monit")]

list_ipc = c("ipc_fipe", "ipc_fipe_aliment", "ipc_fipe_indust", "ipc_fipe_innatura", "ipc_fipe_habit", "ipc_fipe_transp", "ipc_fipe_desp_pes",              
             "ipc_fipe_vest", "ipc_fipe_saude", "ipc_fipe_educacao", "ipc_fipe_comerc", "ipc_fipe_nao_comerc", "ipc_fipe_monit")

dados_ipc_fipe_des <- data.frame("nome" = NA, "valor" = NA)

for (i in list_ipc) {
  d <- data.frame("nome" = i, "valor" = dados[, c(i)])
  dados_ipc_fipe_des <- rbind(dados_ipc_fipe_des, d)
}

dados_ipc_fipe_des <- DropNA(dados_ipc_fipe_des)

test <- data.frame(dados_ipc_fipe_des[dados_ipc_fipe_des["nome"]!="ipc_fipe",])

png(filename="~/Desktop/tcc_pos/plots/plot_aed/analise_des_ipc_fipe.png")
ggplot() +
  geom_violin(data = data.frame(dados_ipc_fipe_des[dados_ipc_fipe_des["nome"]!="ipc_fipe",]), aes(x=nome, y=valor))  +
  geom_violin(data = data.frame(dados_ipc_fipe_des[dados_ipc_fipe_des["nome"]=="ipc_fipe",]), aes(x = nome, y = valor), fill="#B8860B") +
  ggtitle("Distribuição das variáveis do IPC-FIPE") +
  xlab("") +
  ylab("Variação percentual") +
  coord_flip()
dev.off()


# custo cestas por capitais

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/sef_predict/data/app_db.db")
dados <- dbReadTable(con, "dados")
dados$date <- as.Date(strptime(anytime::anydate(ipca$date), "%Y-%m-%d"))

list_custo_cestas <- c("custo_cesta_aracaju", "custo_cesta_belem", "custo_cesta_bh", "custo_cesta_brasilia", "custo_cesta_curitiba", 
"custo_cesta_floripa", "custo_cesta_fortaleza", "custo_cesta_goiania", "custo_cesta_jp", "custo_cesta_salvador", "custo_cesta_natal", 
"custo_cesta_poa", "custo_cesta_recife", "custo_cesta_rj", "custo_cesta_sp", "custo_cesta_vitoria")

d_cestas <- data.frame(matrix(ncol = 16, nrow = 317))
colnames(d_cestas) <- list_custo_cestas
d_cestas$custo_cesta_aracaju <- percentChange(ts(dados$custo_cesta_aracaju))
d_cestas$custo_cesta_belem <- percentChange(ts(dados$custo_cesta_belem))
d_cestas$custo_cesta_bh <- percentChange(ts(dados$custo_cesta_bh))
d_cestas$custo_cesta_brasilia <- percentChange(ts(dados$custo_cesta_brasilia))
d_cestas$custo_cesta_curitiba <- percentChange(ts(dados$custo_cesta_curitiba))
d_cestas$custo_cesta_floripa <- percentChange(ts(dados$custo_cesta_floripa))
d_cestas$custo_cesta_fortaleza <- percentChange(ts(dados$custo_cesta_fortaleza))
d_cestas$custo_cesta_goiania <- percentChange(ts(dados$custo_cesta_goiania))
d_cestas$custo_cesta_jp <- percentChange(ts(dados$custo_cesta_jp))
d_cestas$custo_cesta_salvador <- percentChange(ts(dados$custo_cesta_salvador))
d_cestas$custo_cesta_natal <- percentChange(ts(dados$custo_cesta_natal))
d_cestas$custo_cesta_poa <- percentChange(ts(dados$custo_cesta_poa))
d_cestas$custo_cesta_recife <- percentChange(ts(dados$custo_cesta_recife))
d_cestas$custo_cesta_rj <- percentChange(ts(dados$custo_cesta_rj))
d_cestas$custo_cesta_sp <- percentChange(ts(dados$custo_cesta_sp))
d_cestas$custo_cesta_vitoria <- percentChange(ts(dados$custo_cesta_vitoria))
d_cestas <- DropNA(d_cestas)

dados_custos_cestas <- data.frame("nome" = NA, "valor" = NA)

for (i in list_custo_cestas) {
  d <- data.frame("nome" = i, "valor" = d_cestas[, c(i)])
  dados_custos_cestas <- rbind(dados_custos_cestas, d)
}

dados_custos_cestas <- DropNA(dados_custos_cestas)

png(filename="~/Desktop/tcc_pos/plots/plot_aed/custo_cestas_estados.png")
ggplot(data = dados_custos_cestas, aes(x=nome, y=valor)) +
  geom_violin()  +
  ggtitle("Distribuição dos custos de cestas - por capitais") +
  xlab("") +
  ylab("Variação percentual") + 
  coord_flip()
dev.off()




# expectativas - INPC

library(stringr)

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/sef_predict/data/app_db.db")
dados <- dbReadTable(con, "dados")
dados$date <- as.Date(strptime(anytime::anydate(ipca$date), "%Y-%m-%d"))
dados_exp_inpc <- dados[, c("date", "inpc", "inpc_mean_1", "inpc_dp_1", "inpc_mean_2", "inpc_dp_2", "inpc_mean_3", 
                            "inpc_dp_3", "inpc_mean_4", "inpc_dp_4" )]

dados_exp_inpc$min_inpc_1 <- dados_exp_inpc$inpc_mean_1 * 1 - dados_exp_inpc$inpc_dp_1
dados_exp_inpc$max_inpc_1 <- dados_exp_inpc$inpc_mean_1 * 1 + dados_exp_inpc$inpc_dp_1
dados_exp_inpc$min_inpc_2 <- dados_exp_inpc$inpc_mean_2 * 1 - dados_exp_inpc$inpc_dp_2
dados_exp_inpc$max_inpc_2 <- dados_exp_inpc$inpc_mean_2 * 1 + dados_exp_inpc$inpc_dp_2
dados_exp_inpc$min_inpc_3 <- dados_exp_inpc$inpc_mean_3 * 1 - dados_exp_inpc$inpc_dp_3
dados_exp_inpc$max_inpc_3 <- dados_exp_inpc$inpc_mean_3 * 1 + dados_exp_inpc$inpc_dp_3
dados_exp_inpc$min_inpc_4 <- dados_exp_inpc$inpc_mean_4 * 1 - dados_exp_inpc$inpc_dp_4
dados_exp_inpc$max_inpc_4 <- dados_exp_inpc$inpc_mean_4 * 1 + dados_exp_inpc$inpc_dp_4


dados_exp_inpc <- DropNA(dados_exp_inpc, Var = c("inpc_mean_1"))

png(filename="~/Desktop/tcc_pos/plots/plot_aed/expectativas/exp_inpc_1.png")
ggplot(dados_exp_inpc, aes(x=date, y=inpc_mean_1)) +
  geom_line(data = dados_exp_inpc, aes(x=date, y=inpc_mean_1), size=0.3, alpha=0.8) +
  geom_line(data = dados_exp_inpc, aes(x=date, y=inpc), size=0.3, alpha=0.8) +
  geom_ribbon(aes(ymin=min_inpc_1, ymax=max_inpc_1) ,fill="blue", alpha=0.3) +
  labs(title = "INPC e Expectativas do mercado sobre o índice - um mês", x = "Meses", y = "Variação percentual") 
dev.off()

png(filename="~/Desktop/tcc_pos/plots/plot_aed/expectativas/exp_inpc_2.png")
ggplot(dados_exp_inpc, aes(x=date, y=inpc_mean_2)) +
  geom_line(data = dados_exp_inpc, aes(x=date, y=inpc_mean_2), size=0.3, alpha=0.8) +
  geom_line(data = dados_exp_inpc, aes(x=date, y=inpc), size=0.3, alpha=0.8) +
  geom_ribbon(aes(ymin=min_inpc_2, ymax=max_inpc_2) ,fill="blue", alpha=0.3) +
  labs(title = "INPC e Expectativas do mercado sobre o índice - dois meses", x = "Meses", y = "Variação percentual") 
dev.off()

png(filename="~/Desktop/tcc_pos/plots/plot_aed/expectativas/exp_inpc_3.png")
ggplot(dados_exp_inpc, aes(x=date, y=inpc_mean_3)) +
  geom_line(data = dados_exp_inpc, aes(x=date, y=inpc_mean_3), size=0.3, alpha=0.8) +
  geom_line(data = dados_exp_inpc, aes(x=date, y=inpc), size=0.3, alpha=0.8) +
  geom_ribbon(aes(ymin=min_inpc_3, ymax=max_inpc_3) ,fill="blue", alpha=0.3) +
  labs(title = "INPC e Expectativas do mercado sobre o índice - três meses", x = "Meses", y = "Variação percentual") 
dev.off()

png(filename="~/Desktop/tcc_pos/plots/plot_aed/expectativas/exp_inpc_4.png")
ggplot(dados_exp_inpc, aes(x=date, y=inpc_mean_4)) +
  geom_line(data = dados_exp_inpc, aes(x=date, y=inpc_mean_4), size=0.3, alpha=0.8) +
  geom_line(data = dados_exp_inpc, aes(x=date, y=inpc), size=0.3, alpha=0.8) +
  geom_ribbon(aes(ymin=min_inpc_4, ymax=max_inpc_4) ,fill="blue", alpha=0.3) +
  labs(title = "INPC e Expectativas do mercado sobre o índice - quatro meses", x = "Meses", y = "Variação percentual") 
dev.off()




# expectativas - IGPM

library(stringr)

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/sef_predict/data/app_db.db")
dados <- dbReadTable(con, "dados")
dados$date <- as.Date(strptime(anytime::anydate(ipca$date), "%Y-%m-%d"))
dados_exp_igpm <- dados[, c("date", "igpm", "igp_m_mean_1", "igp_m_dp_1", "igp_m_mean_2", "igp_m_dp_2", "igp_m_mean_3", 
                            "igp_m_dp_3", "igp_m_mean_4", "igp_m_dp_4" )]

dados_exp_igpm$min_igpm_1 <- dados_exp_igpm$igp_m_mean_1 * 1 - dados_exp_igpm$igp_m_dp_1
dados_exp_igpm$max_igpm_1 <- dados_exp_igpm$igp_m_mean_1 * 1 + dados_exp_igpm$igp_m_dp_1
dados_exp_igpm$min_igpm_2 <- dados_exp_igpm$igp_m_mean_2 * 1 - dados_exp_igpm$igp_m_dp_2
dados_exp_igpm$max_igpm_2 <- dados_exp_igpm$igp_m_mean_2 * 1 + dados_exp_igpm$igp_m_dp_2
dados_exp_igpm$min_igpm_3 <- dados_exp_igpm$igp_m_mean_3 * 1 - dados_exp_igpm$igp_m_dp_3
dados_exp_igpm$max_igpm_3 <- dados_exp_igpm$igp_m_mean_3 * 1 + dados_exp_igpm$igp_m_dp_3
dados_exp_igpm$min_igpm_4 <- dados_exp_igpm$igp_m_mean_4 * 1 - dados_exp_igpm$igp_m_dp_4
dados_exp_igpm$max_igpm_4 <- dados_exp_igpm$igp_m_mean_4 * 1 + dados_exp_igpm$igp_m_dp_4

dados_exp_igpm <- DropNA(dados_exp_igpm, Var = c("igp_m_mean_1"))

png(filename="~/Desktop/tcc_pos/plots/plot_aed/expectativas/exp_igpm_1.png")
ggplot(dados_exp_igpm, aes(x=date, y=igp_m_mean_1)) +
  geom_line(data = dados_exp_igpm, aes(x=date, y=igp_m_mean_1), size=0.3, alpha=0.8) +
  geom_line(data = dados_exp_igpm, aes(x=date, y=igpm), size=0.3, alpha=0.8) +
  geom_ribbon(aes(ymin=min_igpm_1, ymax=max_igpm_1) ,fill="blue", alpha=0.3) +
  labs(title = "IGP-M e Expectativas do mercado sobre o índice - um mês", x = "Meses", y = "Variação percentual") 
dev.off()

png(filename="~/Desktop/tcc_pos/plots/plot_aed/expectativas/exp_igpm_2.png")
ggplot(dados_exp_igpm, aes(x=date, y=igp_m_mean_2)) +
  geom_line(data = dados_exp_igpm, aes(x=date, y=igp_m_mean_2), size=0.3, alpha=0.8) +
  geom_line(data = dados_exp_igpm, aes(x=date, y=igpm), size=0.3, alpha=0.8) +
  geom_ribbon(aes(ymin=min_igpm_2, ymax=max_igpm_2) ,fill="blue", alpha=0.3) +
  labs(title = "IGP-M e Expectativas do mercado sobre o índice - dois meses", x = "Meses", y = "Variação percentual") 
dev.off()

png(filename="~/Desktop/tcc_pos/plots/plot_aed/expectativas/exp_igpm_3.png")
ggplot(dados_exp_igpm, aes(x=date, y=igp_m_mean_3)) +
  geom_line(data = dados_exp_igpm, aes(x=date, y=igp_m_mean_3), size=0.3, alpha=0.8) +
  geom_line(data = dados_exp_igpm, aes(x=date, y=igpm), size=0.3, alpha=0.8) +
  geom_ribbon(aes(ymin=min_igpm_3, ymax=max_igpm_3) ,fill="blue", alpha=0.3) +
  labs(title = "IGP-M e Expectativas do mercado sobre o índice - três meses", x = "Meses", y = "Variação percentual") 
dev.off()

png(filename="~/Desktop/tcc_pos/plots/plot_aed/expectativas/exp_igpm_4.png")
ggplot(dados_exp_igpm, aes(x=date, y=igp_m_mean_4)) +
  geom_line(data = dados_exp_igpm, aes(x=date, y=igp_m_mean_4), size=0.3, alpha=0.8) +
  geom_line(data = dados_exp_igpm, aes(x=date, y=igpm), size=0.3, alpha=0.8) +
  geom_ribbon(aes(ymin=min_igpm_4, ymax=max_igpm_4) ,fill="blue", alpha=0.3) +
  labs(title = "IGP-M e Expectativas do mercado sobre o índice - quatro meses", x = "Meses", y = "Variação percentual") 
dev.off()

# expectativas - IPCA

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/sef_predict/data/app_db.db")
dados <- dbReadTable(con, "dados")
dados$date <- as.Date(strptime(anytime::anydate(ipca$date), "%Y-%m-%d"))
dados_exp_ipca <- dados[, c("date", "ipca", "ipca_mean_1", "ipca_dp_1", "ipca_mean_2", "ipca_dp_2", "ipca_mean_3", 
                            "ipca_dp_3", "ipca_mean_4", "ipca_dp_4" )]

dados_exp_ipca$min_ipca_1 <- dados_exp_ipca$ipca_mean_1 * 1 - dados_exp_ipca$ipca_dp_1
dados_exp_ipca$max_ipca_1 <- dados_exp_ipca$ipca_mean_1 * 1 + dados_exp_ipca$ipca_dp_1
dados_exp_ipca$min_ipca_2 <- dados_exp_ipca$ipca_mean_2 * 1 - dados_exp_ipca$ipca_dp_2
dados_exp_ipca$max_ipca_2 <- dados_exp_ipca$ipca_mean_2 * 1 + dados_exp_ipca$ipca_dp_2
dados_exp_ipca$min_ipca_3 <- dados_exp_ipca$ipca_mean_3 * 1 - dados_exp_ipca$ipca_dp_3
dados_exp_ipca$max_ipca_3 <- dados_exp_ipca$ipca_mean_3 * 1 + dados_exp_ipca$ipca_dp_3
dados_exp_ipca$min_ipca_4 <- dados_exp_ipca$ipca_mean_4 * 1 - dados_exp_ipca$ipca_dp_4
dados_exp_ipca$max_ipca_4 <- dados_exp_ipca$ipca_mean_4 * 1 + dados_exp_ipca$ipca_dp_4

dados_exp_ipca <- DropNA(dados_exp_ipca, Var = c("ipca_mean_1"))

png(filename="~/Desktop/tcc_pos/plots/plot_aed/expectativas/exp_ipca_1.png")
ggplot(dados_exp_ipca, aes(x=date, y=ipca_mean_1)) +
  geom_line(data = dados_exp_ipca, aes(x=date, y=ipca_mean_1), size=0.3, alpha=0.8) +
  geom_line(data = dados_exp_ipca, aes(x=date, y=ipca), size=0.3, alpha=0.8) +
  geom_ribbon(aes(ymin=min_ipca_1, ymax=max_ipca_1) ,fill="blue", alpha=0.3) +
  labs(title = "IPCA e Expectativas do mercado sobre o índice - um mês", x = "Meses", y = "Variação percentual") 
dev.off()

png(filename="~/Desktop/tcc_pos/plots/plot_aed/expectativas/exp_ipca_2.png")
ggplot(dados_exp_ipca, aes(x=date, y=ipca_mean_2)) +
  geom_line(data = dados_exp_ipca, aes(x=date, y=ipca_mean_2), size=0.3, alpha=0.8) +
  geom_line(data = dados_exp_ipca, aes(x=date, y=ipca), size=0.3, alpha=0.8) +
  geom_ribbon(aes(ymin=min_ipca_2, ymax=max_ipca_2) ,fill="blue", alpha=0.3) +
  labs(title = "IPCA e Expectativas do mercado sobre o índice - dois meses", x = "Meses", y = "Variação percentual") 
dev.off()

png(filename="~/Desktop/tcc_pos/plots/plot_aed/expectativas/exp_ipca_3.png")
ggplot(dados_exp_ipca, aes(x=date, y=ipca_mean_3)) +
  geom_line(data = dados_exp_ipca, aes(x=date, y=ipca_mean_3), size=0.3, alpha=0.8) +
  geom_line(data = dados_exp_ipca, aes(x=date, y=ipca), size=0.3, alpha=0.8) +
  geom_ribbon(aes(ymin=min_ipca_3, ymax=max_ipca_3) ,fill="blue", alpha=0.3) +
  labs(title = "IPCA e Expectativas do mercado sobre o índice - três meses", x = "Meses", y = "Variação percentual") 
dev.off()

png(filename="~/Desktop/tcc_pos/plots/plot_aed/expectativas/exp_ipca_4.png")
ggplot(dados_exp_ipca, aes(x=date, y=ipca_mean_4)) +
  geom_line(data = dados_exp_ipca, aes(x=date, y=ipca_mean_4), size=0.3, alpha=0.8) +
  geom_line(data = dados_exp_ipca, aes(x=date, y=ipca), size=0.3, alpha=0.8) +
  geom_ribbon(aes(ymin=min_ipca_4, ymax=max_ipca_4), fill="blue", alpha=0.3) +
  labs(title = "IPCA e Expectativas do mercado sobre o índice - quatro meses", x = "Meses", y = "Variação percentual") 
dev.off()





# outros indicadores

### icbr

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/sef_predict/data/app_db.db")
dados <- dbReadTable(con, "dados")
dados$date <- as.Date(strptime(anytime::anydate(ipca$date), "%Y-%m-%d"))
dados_icbr <- dados[, c("date", "ipca", "ipca_e", "icbr", "icbr_agro", "icbr_energia", "icbr_metal")]

dados_icbr <- DropNA(dados_icbr, Var = c("icbr"))

colors <- c("icbr" = "#00AFBB", "icbr_agro" = "#E88974", "icbr_energia" = "#ecd382", "icbr_metal" = "#c29ef3")

png(filename="~/Desktop/tcc_pos/plots/plot_aed/icbr.png")
ggplot() +
  geom_line(data = dados_icbr, aes(x=date, y=icbr, color = "icbr")) + 
  geom_line(data = dados_icbr, aes(x=date, y=icbr_agro, color = "icbr_agro")) +
  geom_line(data = dados_icbr, aes(x=date, y=icbr_energia, color = "icbr_energia")) +
  geom_line(data = dados_icbr, aes(x=date, y=icbr_metal, color = "icbr_metal")) +
  labs(title = "ICBR - Índice de Custos", x = "Meses", y = "Valor do ICBR", color = "Índices") +
  scale_colour_manual(values = colors) + 
  theme(legend.position='bottom')
dev.off()


percentChange(ts(dados$pib_mensal))


### atividade economica

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/sef_predict/data/app_db.db")
dados <- dbReadTable(con, "dados")
dados$date <- as.Date(strptime(anytime::anydate(ipca$date), "%Y-%m-%d"))
dados_pib <- dados[, c("date", "ipca", "pib_mensal", "pib_acum_12meses", "pib_acum_ult12meses")]

ggplot() +
  geom_line(data = dados_pib, aes(x=date, y=ipca), color = "#00AFBB") + 
  geom_line(data = dados_pib, aes(x=date, y=icbr_agro), color = "#E88974") +
  geom_line(data = dados_pib, aes(x=date, y=icbr_energia), color = "#ecd382") +
  geom_line(data = dados_pib, aes(x=date, y=icbr_metal), color = "#c29ef3") +
  theme(legend.position='bottom') +
  labs(title = "IPCA e Atividade Econômica", x = "Meses", y = "Variação percentual") 




