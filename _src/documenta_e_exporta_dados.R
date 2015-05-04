library(Hmisc)
## Dados de volume e pluviometria de todos os reservatorios
## Recuperação automatica de http://www2.sabesp.com.br/mananciais/DivulgacaoSiteSabesp.aspx
## Pela ferramenta  http://mananciais.tk/
## Pode conter erros de leitura devido ao processo automatico de recuperacao ##
rsp <- upData(rsp,
              labels=c(
                  data="Data (Ano-mes-dia)",
                  manancial="Nomenclatura SABESP do manancial",
                  volume="Volume armazenado em percentual do volume util (nao corrigido para uso de volume morto)",
                  pluviometria="Pluviometria acumulada do dia na area do sistema"
                  ),
              units=c(pluviometria="mm")
              )
## Vazoes de entrada e saida no sistema Cantareira
## Recuperação automatica de http://www2.sabesp.com.br/mananciais/divulgacaopcj.aspx
## Pode conter erros de elitura devido ao processo automatico de recuperacao ##
fluxos <- upData(fluxos,
                 labels=c(
                     date="Data (ano-mes-dia)",
                     Jaguari_QNat="Vazao afluente no reservatorio de Jaguari-Jacarei",
                     Jaguari_QJus="Vazao defluente do reservatorio de Jaguari-Jacarei",
                     Jaguari_Vop="Volume operacional percentual do reservatorio Jaguari-Jacarei",
                     Cachoeira_QNat="Vazao afluente no reservatorio de Cachoeira",
                     Cachoeira_QJus="Vazao defluente do reservatorio de Cachoeira",
                     Cachoeira_Vop="Volume operacional do reservatorio Jaguari-Jacarei",
                     Atibainha_QNat="Vazao afluente no reservatorio de Atibainha",
                     Atibainha_QJus="Vazao defluente do reservatorio de Atibainha",
                     Atibainha_Vop="Volume operacional percentual do reservatorio Atibainha",
                     PaivaC_QNat="Vazao afluente no reservatorio Paiva Castro",
                     PaivaC_QJus="Vazao defluente do reservatorio Paiva Castro",
                     PaivaC_Vop="Volume operacional percentual do reservatorio Paiva Castro",
                     QESI="Vazão extraida do reservatorio Paiva Castro para a RMSP",
                     afluente="Vazao afluente total (soma dos QNat)",
                     defluente="Vazao defluente total (soma dos QJus e QESI)",
                     afluente.m="Media da vazao afluente dos 30 dias anteriores"
                     ),
                 units=c(
                     Jaguari_QNat="m3/s",
                     Jaguari_QJus="m3/s",
                     Cachoeira_QNat="m3/s",
                     Cachoeira_QJus="m3/s",
                     Atibainha_QNat="m3/s",
                     Atibainha_QJus="m3/s",
                     Atibainha_Vop="",
                     PaivaC_QNat="m3/s",
                     PaivaC_QJus="m3/s",
                     QESI="m3/s",
                     afluente="m3/dia",
                     defluente="m3/dia",
                     afluente.m="m3/dia"
                     )
                 )
## Dados do sistema Cantareira usados nos modelos e graficos
## Sao os dados acima mas processados pelo codigo em dataprep.R
cant.dim5.df <- upData(as.data.frame(cant.dim5),
                    labels=c(
                        pluv="Pluviometria acumulada do dia na area do sistema",
                        v.rel="Volume armazenado em percentual do volume util",
                        v.rel2="Volume armazenado em percentual do volume total",
                        v.abs="Volume armazenado",
                        pluv.m="Pluviometria media dos 30 dias anteriores",
                        afluente="Vazao afluente total (soma dos QNat)",
                        defluente="Vazao defluente total (soma dos QJus e QESI)",
                        afluente.m="Media da vazao afluente dos 30 dias anteriores"
                        ),
                    units=c(
                        pluv="mm",
                        v.abs="m3",
                        pluv.m="mm",
                        afluente="m3/dia",
                        defluente="m3/dia",
                        afluente.m="m3/dia"
                        )
                       )
## Projecoes e intervalos de credibilidade para os proximos 30 dias
proj.30 <- as.data.frame(
    window(c3[,c("mean.75","lower.75","upper.75", "mean.100","lower.100","upper.100", "mean.125","lower.125","upper.125")],
           start=min(time(ph.next)+1), end=max(time(ph.next))))
proj.30 <- upData(proj.30,
                  labels=c(
                      mean.75 = "Volume projetado para pluviosidade 25% abaixo da media historica",
                      lower.75 = "Limite inferior de credibilidade a 95% do volume projetado para pluviosidade 25% abaixo da media historica",
                      upper.75= "Limite superior de credibilidade a 95% do volume projetado para pluviosidade 25% abaixo da media historica",
                      mean.100 = "Volume projetado para pluviosidade na media historica",
                      lower.100 = "Limite inferior de credibilidade a 95% do volume projetado para pluviosidade na  media historica",
                      upper.100= "Limite superior de credibilidade a 95% do volume projetado para pluviosidade na media historica",
                      mean.125 = "Volume projetado para pluviosidade 25% acima da media historica",
                      lower.125 = "Limite inferior de credibilidade a 95% do volume projetado para pluviosidade 25% acima da media historica",
                      upper.125= "Limite superior de credibilidade a 95% do volume projetado para pluviosidade 25% acima da media historica"
                      ),
                  units=c(
                      mean.75 = "bilhoes de m3",
                      lower.75 = "bilhoes de m3",
                      upper.75= "bilhoes de m3",
                      mean.100 = "bilhoes de m3",
                      lower.100 = "bilhoes de m3",
                      upper.100= "bilhoes de m3",
                      mean.125 = "bilhoes de m3",
                      lower.125 = "bilhoes de m3",
                      upper.125= "bilhoes de m3"
                      )
    
    )

## salva os arquivos em formato csv
write.csv(cant.dim5.df, dec=".", file="../data/dados_de_trabalho.csv")
write.csv(proj.30, dec=".", file="../data/proj30.csv")
tmp1 <- html(contents(rsp), file="../dados_metadata.html")
tmp2 <- html(contents(fluxos), file="../data_ocr_cor2_metadata.html")
tmp3 <- html(contents(cant.dim5.df), file="../planilha_de_trabalho_metadata.html")
tmp3 <- html(contents(proj.30), file="../projecoes_30_dias_metadata.html")
