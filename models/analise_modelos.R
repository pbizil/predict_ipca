library(DBI)
library(ggplot2)
library(rjson)
library(anytime)
library(naniar)           
library(Metrics)

# target

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/tcc_pos/data/app_db.db")
dados <- dbReadTable(con, "preds_l1")
colnames(dados)[3] <- c("expectativas_ipca")
dados$date <- as.Date(strptime(anytime::anydate(dados$date), "%Y-%m-%d"))

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_output/ipca_serie_target.png")
ggplot() +
  geom_line(data = dados, aes(x=date, y=y1, colour = "IPCA Mensal")) +
  geom_line(data = dados, aes(x=date, y=expectativas_ipca, colour = "Expectativas IPCA")) + 
  labs(title = "IPCA mensal e Expectativa - jan/2015 a jun/2021", x = "Meses", y = "Variação percentual") +
  scale_colour_manual("", breaks = c("IPCA Mensal", "Expectativas IPCA"), values = c("black", "blue")) + 
  theme(legend.position='bottom')

dev.off()

# 1 mes

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/tcc_pos/data/app_db.db")
dados <- dbReadTable(con, "preds_l1")
colnames(dados)[3] <- c("expectativas_ipca")
dados$date <- as.Date(strptime(anytime::anydate(dados$date), "%Y-%m-%d"))

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_output/ipca_pred_1mes_cb.png")
ggplot() +
  geom_line(data = dados, aes(x=date, y=y1, colour = "IPCA Mensal")) +
  geom_line(data = dados, aes(x=date, y=expectativas_ipca, colour = "Expectativas IPCA")) + 
  geom_line(data = dados, aes(x=date, y=y_preds_cb_1, colour = "Predição IPCA - Catboost")) + 
  labs(title = "IPCA mensal, Expectativa e Predição Catboost de um mês \n jan/2015 a jun/2021", x = "Meses", y = "Variação percentual") +
  scale_colour_manual("", breaks = c("IPCA Mensal", "Expectativas IPCA", "Predição IPCA - Catboost"), values = c("black", "blue", "red")) + 
  theme(legend.position='bottom') 
dev.off()

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_output/ipca_pred_1mes_xg.png")
ggplot() +
  geom_line(data = dados, aes(x=date, y=y1, colour = "IPCA Mensal")) +
  geom_line(data = dados, aes(x=date, y=expectativas_ipca, colour = "Expectativas IPCA")) + 
  geom_line(data = dados, aes(x=date, y=y_preds_xg_1, colour = "Predição IPCA - XGBoost")) + 
  labs(title = "IPCA mensal, Expectativa e Predição XGBoost de um mês \n jan/2015 a jun/2021", x = "Meses", y = "Variação percentual") +
  scale_colour_manual("", breaks = c("IPCA Mensal", "Expectativas IPCA", "Predição IPCA - XGBoost"), values = c("black", "blue", "red")) + 
  theme(legend.position='bottom')
dev.off()

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_output/ipca_pred_1mes_lgbm.png")
ggplot() +
  geom_line(data = dados, aes(x=date, y=y1, colour = "IPCA Mensal")) +
  geom_line(data = dados, aes(x=date, y=expectativas_ipca, colour = "Expectativas IPCA")) + 
  geom_line(data = dados, aes(x=date, y=y_preds_lgbm_1, colour = "Predição IPCA - LGBM")) + 
  labs(title = "IPCA mensal, Expectativa e Predição LGBM de um mês \n jan/2015 a jun/2021", x = "Meses", y = "Variação percentual") +
  scale_colour_manual("", breaks = c("IPCA Mensal", "Expectativas IPCA", "Predição IPCA - LGBM"), values = c("black", "blue", "red")) + 
  theme(legend.position='bottom')
dev.off()

# 2 meses

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/tcc_pos/data/app_db.db")
dados <- dbReadTable(con, "preds_l2")
colnames(dados)[3] <- c("expectativas_ipca")
dados$date <- as.Date(strptime(anytime::anydate(dados$date), "%Y-%m-%d"))

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_output/ipca_pred_2meses_cb.png")
ggplot() +
  geom_line(data = dados, aes(x=date, y=y2, colour = "IPCA Mensal")) +
  geom_line(data = dados, aes(x=date, y=expectativas_ipca, colour = "Expectativas IPCA")) + 
  geom_line(data = dados, aes(x=date, y=y_preds_cb_2, colour = "Predição IPCA - Catboost")) + 
  labs(title = "IPCA mensal, Expectativa e Predição Catboost de dois meses \n jan/2015 a jun/2021", x = "Meses", y = "Variação percentual") +
  scale_colour_manual("", breaks = c("IPCA Mensal", "Expectativas IPCA", "Predição IPCA - Catboost"), values = c("black", "blue", "red")) + 
  theme(legend.position='bottom')
dev.off()

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_output/ipca_pred_2meses_xg.png")
ggplot() +
  geom_line(data = dados, aes(x=date, y=y2, colour = "IPCA Mensal")) +
  geom_line(data = dados, aes(x=date, y=expectativas_ipca, colour = "Expectativas IPCA")) + 
  geom_line(data = dados, aes(x=date, y=y_preds_xg_2, colour = "Predição IPCA - XGBoost")) + 
  labs(title = "IPCA mensal, Expectativa e Predição XGBoost de dois meses \n jan/2015 a jun/2021", x = "Meses", y = "Variação percentual") +
  scale_colour_manual("", breaks = c("IPCA Mensal", "Expectativas IPCA", "Predição IPCA - XGBoost"), values = c("black", "blue", "red")) + 
  theme(legend.position='bottom')
dev.off()

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_output/ipca_pred_2meses_lgbm.png")
ggplot() +
  geom_line(data = dados, aes(x=date, y=y2, colour = "IPCA Mensal")) +
  geom_line(data = dados, aes(x=date, y=expectativas_ipca, colour = "Expectativas IPCA")) + 
  geom_line(data = dados, aes(x=date, y=y_preds_lgbm_2, colour = "Predição IPCA - LGBM")) + 
  labs(title = "IPCA mensal, Expectativa e Predição LGBM de dois meses \n jan/2015 a jun/2021", x = "Meses", y = "Variação percentual") +
  scale_colour_manual("", breaks = c("IPCA Mensal", "Expectativas IPCA", "Predição IPCA - LGBM"), values = c("black", "blue", "red")) + 
  theme(legend.position='bottom')
dev.off()

# 3 meses

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/tcc_pos/data/app_db.db")
dados <- dbReadTable(con, "preds_l3")
colnames(dados)[3] <- c("expectativas_ipca")
dados$date <- as.Date(strptime(anytime::anydate(dados$date), "%Y-%m-%d"))

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_output/ipca_pred_3meses_cb.png")
ggplot() +
  geom_line(data = dados, aes(x=date, y=y3, colour = "IPCA Mensal")) +
  geom_line(data = dados, aes(x=date, y=expectativas_ipca, colour = "Expectativas IPCA")) + 
  geom_line(data = dados, aes(x=date, y=y_preds_cb_3, colour = "Predição IPCA - Catboost")) + 
  labs(title = "IPCA mensal, Expectativa e Predição Catboost de três meses \n jan/2015 a jun/2021", x = "Meses", y = "Variação percentual") +
  scale_colour_manual("", breaks = c("IPCA Mensal", "Expectativas IPCA", "Predição IPCA - Catboost"), values = c("black", "blue", "red")) + 
  theme(legend.position='bottom')
dev.off()

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_output/ipca_pred_3meses_xg.png")
ggplot() +
  geom_line(data = dados, aes(x=date, y=y3, colour = "IPCA Mensal")) +
  geom_line(data = dados, aes(x=date, y=expectativas_ipca, colour = "Expectativas IPCA")) + 
  geom_line(data = dados, aes(x=date, y=y_preds_xg_3, colour = "Predição IPCA - XGBoost")) + 
  labs(title = "IPCA mensal, Expectativa e Predição XGBoost de três meses \n jan/2015 a jun/2021", x = "Meses", y = "Variação percentual") +
  scale_colour_manual("", breaks = c("IPCA Mensal", "Expectativas IPCA", "Predição IPCA - XGBoost"), values = c("black", "blue", "red")) + 
  theme(legend.position='bottom')
dev.off()

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_output/ipca_pred_3meses_lgbm.png")
ggplot() +
  geom_line(data = dados, aes(x=date, y=y3, colour = "IPCA Mensal")) +
  geom_line(data = dados, aes(x=date, y=expectativas_ipca, colour = "Expectativas IPCA")) + 
  geom_line(data = dados, aes(x=date, y=y_preds_lgbm_3, colour = "Predição IPCA - LGBM")) + 
  labs(title = "IPCA mensal, Expectativa e Predição LGBM de três meses \n jan/2015 a jun/2021", x = "Meses", y = "Variação percentual") +
  scale_colour_manual("", breaks = c("IPCA Mensal", "Expectativas IPCA", "Predição IPCA - LGBM"), values = c("black", "blue", "red")) + 
  theme(legend.position='bottom')
dev.off()

# 4 meses

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/tcc_pos/data/app_db.db")
dados <- dbReadTable(con, "preds_l4")
colnames(dados)[3] <- c("expectativas_ipca")
dados$date <- as.Date(strptime(anytime::anydate(dados$date), "%Y-%m-%d"))

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_output/ipca_pred_4meses_cb.png")
ggplot() +
  geom_line(data = dados, aes(x=date, y=y4, colour = "IPCA Mensal")) +
  geom_line(data = dados, aes(x=date, y=expectativas_ipca, colour = "Expectativas IPCA")) + 
  geom_line(data = dados, aes(x=date, y=y_preds_cb_4, colour = "Predição IPCA - Catboost")) + 
  labs(title = "IPCA mensal, Expectativa e Predição Catboost de quatro meses \n jan/2015 a jun/2021", x = "Meses", y = "Variação percentual") +
  scale_colour_manual("", breaks = c("IPCA Mensal", "Expectativas IPCA", "Predição IPCA - Catboost"), values = c("black", "blue", "red")) + 
  theme(legend.position='bottom')
dev.off()

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_output/ipca_pred_4meses_xg.png")
ggplot() +
  geom_line(data = dados, aes(x=date, y=y4, colour = "IPCA Mensal")) +
  geom_line(data = dados, aes(x=date, y=expectativas_ipca, colour = "Expectativas IPCA")) + 
  geom_line(data = dados, aes(x=date, y=y_preds_xg_4, colour = "Predição IPCA - XGBoost")) + 
  labs(title = "IPCA mensal, Expectativa e Predição XGBoost de quatro meses \n jan/2015 a jun/2021", x = "Meses", y = "Variação percentual") +
  scale_colour_manual("", breaks = c("IPCA Mensal", "Expectativas IPCA", "Predição IPCA - XGBoost"), values = c("black", "blue", "red")) + 
  theme(legend.position='bottom')
dev.off()

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_output/ipca_pred_4meses_lgbm.png")
ggplot() +
  geom_line(data = dados, aes(x=date, y=y4, colour = "IPCA Mensal")) +
  geom_line(data = dados, aes(x=date, y=expectativas_ipca, colour = "Expectativas IPCA")) + 
  geom_line(data = dados, aes(x=date, y=y_preds_lgbm_4, colour = "Predição IPCA - LGBM")) + 
  labs(title = "IPCA mensal, Expectativa e Predição LGBM de quatro meses \n jan/2015 a jun/2021", x = "Meses", y = "Variação percentual") +
  scale_colour_manual("", breaks = c("IPCA Mensal", "Expectativas IPCA", "Predição IPCA - LGBM"), values = c("black", "blue", "red")) + 
  theme(legend.position='bottom')
dev.off()


# desempenho dos modelos

# 1 mes

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/tcc_pos/data/app_db.db")
dados <- dbReadTable(con, "preds_l1")
colnames(dados)[3] <- c("expectativas_ipca")

dados_r2 <- data.frame("Predições" = c("Expectativa de mercado", "Catboost", "XGBoost", "LGBM"), "Desempenho" = c(mse(dados$y1, dados$expectativas_ipca), mse(dados$y1, dados$y_preds_cb_1), mse(dados$y1, dados$y_preds_xg_1), mse(dados$y1, dados$y_preds_lgbm_1)),
                       "Fonte" = c("Expectativa", "Modelo", "Modelo", "Modelo"))

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_desempenho/ipca_pred_desemp_1mes.png")
ggplot(data=dados_r2, aes(x=reorder(Predições, -Desempenho), y=Desempenho, fill=Fonte)) + 
  geom_bar(position="stack", stat = "identity", width=0.4) +
  geom_text(aes(label=Desempenho), position=position_dodge(width=1), hjust = 1.2) +
  ggtitle("Desempenho modelos e expectativa de mercado para \n predição de inflação em um mês - valor do mse") + 
  xlab("Fonte das predições") + ylab("Desempenho (mse)") +
  theme(legend.position='bottom') +
  coord_flip()
dev.off()

# 2 meses

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/tcc_pos/data/app_db.db")
dados <- dbReadTable(con, "preds_l2")
colnames(dados)[3] <- c("expectativas_ipca")

dados_r2 <- data.frame("Predições" = c("Expectativa de mercado", "Catboost", "XGBoost", "LGBM"), "Desempenho" = c(mse(dados$y2, dados$expectativas_ipca), mse(dados$y2, dados$y_preds_cb_2), mse(dados$y2, dados$y_preds_xg_2), mse(dados$y2, dados$y_preds_lgbm_2)),
                       "Fonte" = c("Expectativa", "Modelo", "Modelo", "Modelo"))

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_desempenho/ipca_pred_desemp_2meses.png")
ggplot(data=dados_r2, aes(x=reorder(Predições, -Desempenho), y=Desempenho, fill=Fonte)) + 
  geom_bar(position="stack", stat = "identity", width=0.4) +
  geom_text(aes(label=Desempenho), position=position_dodge(width=1), hjust = 1.2) +
  ggtitle("Desempenho modelos e expectativa de mercado para \n predição de inflação em dois meses - valor do mse") + 
  xlab("Fonte das predições") + ylab("Desempenho (mse)") +
  theme(legend.position='bottom') +
  coord_flip()
dev.off()

# 3 meses

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/tcc_pos/data/app_db.db")
dados <- dbReadTable(con, "preds_l3")
colnames(dados)[3] <- c("expectativas_ipca")

dados_r2 <- data.frame("Predições" = c("Expectativa de mercado", "Catboost", "XGBoost", "LGBM"), "Desempenho" = c(mse(dados$y3, dados$expectativas_ipca), mse(dados$y3, dados$y_preds_cb_3), mse(dados$y3, dados$y_preds_xg_3), mse(dados$y3, dados$y_preds_lgbm_3)),
                       "Fonte" = c("Expectativa", "Modelo", "Modelo", "Modelo"))

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_desempenho/ipca_pred_desemp_3meses.png")
ggplot(data=dados_r2, aes(x=reorder(Predições, -Desempenho), y=Desempenho, fill=Fonte)) + 
  geom_bar(position="stack", stat = "identity", width=0.4) +
  geom_text(aes(label=Desempenho), position=position_dodge(width=1), hjust = 1.2) +
  ggtitle("Desempenho modelos e expectativa de mercado para \n predição de inflação em três meses - valor do mse") + 
  xlab("Fonte das predições") + ylab("Desempenho (mse)") +
  theme(legend.position='bottom') +
  coord_flip()
dev.off()

# 4 meses

con <- dbConnect(RSQLite::SQLite(), "/Users/pbizil/Desktop/tcc_pos/data/app_db.db")
dados <- dbReadTable(con, "preds_l4")
colnames(dados)[3] <- c("expectativas_ipca")

dados_r2 <- data.frame("Predições" = c("Expectativa de mercado", "Catboost", "XGBoost", "LGBM"), "Desempenho" = c(mse(dados$y4, dados$expectativas_ipca), mse(dados$y4, dados$y_preds_cb_4), mse(dados$y4, dados$y_preds_xg_4), mse(dados$y4, dados$y_preds_lgbm_4)),
                       "Fonte" = c("Expectativa", "Modelo", "Modelo", "Modelo"))

png(filename="/Users/pbizil/Desktop/tcc_pos/plots/plots_desempenho/ipca_pred_desemp_4meses.png")
ggplot(data=dados_r2, aes(x=reorder(Predições, -Desempenho), y=Desempenho, fill=Fonte)) + 
  geom_bar(position="stack", stat = "identity", width=0.4) +
  geom_text(aes(label=Desempenho), position=position_dodge(width=1), hjust = 1.2) +
  ggtitle("Desempenho modelos e expectativa de mercado para \n predição de inflação em quatro meses - valor do mse") + 
  xlab("Fonte das predições") + ylab("Desempenho (mse)") +
  theme(legend.position='bottom') +
  coord_flip()
dev.off()


