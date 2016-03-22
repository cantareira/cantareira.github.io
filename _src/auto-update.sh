#!/usr/bin/bash

ROOT="$( dirname "${BASH_SOURCE[0]}" )"
year=`date "+%Y"`
hoje=`date +"%Y-%m-%d"`
hoje2=`date +"%Y%m%d"`
hoje3=`date +"%d%b%y"`
hoje4=`date +'%y%m%d'`
ontem=`date -d "yesterday" +"%Y-%m-%d"`
commit=1
novo_boletim=1
error=0

date
pushd "$ROOT/.."

if [ ! -e  "boletins/boletim_mananciais_${hoje}.pdf" ]; then
    # fonte: http://site.sabesp.com.br/site/interna/Default.aspx?secaoId=553
    fname="boletim_mananciais_${hoje3}.pdf"
    wget "http://site.sabesp.com.br/site/uploads/file/boletim/${year}/boletim_mananciais_${hoje3}.pdf"
    if [ $? != 0 ]; then
        wget "http://site.sabesp.com.br/site/uploads/file/boletim/boletim_mananciais_${hoje3}.pdf"
    fi
    if [ $? != 0 ]; then
        fname="boletim_mananciais_$(date +"%d%b_%y").pdf"
        wget "http://site.sabesp.com.br/site/uploads/file/boletim/boletim_mananciais_$(date +"%d%b_%y").pdf"
    fi
    if [ $? != 0 ]; then
        fname="boletim_mananciais_$(date +"%d_%b_%y").pdf"
        wget "http://site.sabesp.com.br/site/uploads/file/boletim/boletim_mananciais_$(date +"%d_%b_%y").pdf"
    fi
    if [ $? = 0 ]; then
        echo "** boletim dos mananciais parece atualizado **"
        mv $fname "boletins/boletim_mananciais_${hoje}.pdf"
        git add "boletins/boletim_mananciais_${hoje}.pdf"
        commit=0
        python _src/boletim_scraper.py "boletins/boletim_mananciais_${hoje}.pdf" "boletins/boletim_mananciais_${ontem}.pdf" data/dados.csv data/data_ocr_cor2.csv data/dados_boletins.csv data/altotiete.csv
        if [ $? = 0 ]; then
            git add data/dados.csv data/data_ocr_cor2.csv data/dados_boletins.csv data/altotiete.csv
            novo_boletim=0
        else
            error=1
            echo "** erro no processamento do boletim dos mananciais **"
        fi
    else
        echo "** boletim dos mananciais ainda não foi atualizado **"
    fi
else
    novo_boletim=0
    echo "** boletim dos mananciais de hoje já foi atualizado **"
fi

# Não usamos mais previsão de chuva do boletim SSPCJ
#if [ ! -e  "SSPCJ_boletimDiario_${hoje2}.pdf" ]; then
#    wget "http://www.sspcj.org.br/images/downloads/SSPCJ_boletimDiario_${hoje2}.pdf"
#    if [ $? = 0 ]; then
#        echo "** boletim SSPCJ parece atualizado **"
#        python _src/pdf_scraper.py "SSPCJ_boletimDiario_${hoje2}.pdf" data/previsoes_boletins_pcj.csv
#        if [ $? = 0 ]; then
#            git add data/previsoes_boletins_pcj.csv
#            commit=0
#        else
#            error=1
#            echo "** erro no processamento do boletim SSPCJ **"
#        fi
#    else
#        echo "** boletim SSPCJ ainda não foi atualizado **"
#    fi
#else
#    echo "** boletim SSPCJ de hoje já foi atualizado **"
#fi

#python _src/somar_scraper.py "Cantareira" "data/prev_somar_novo.csv"
#if [ $? = 0 ]; then
#    diff -q "data/prev_somar_novo.csv" "data/prev_somar.csv"
#    if [ $? != 0 ]; then
#        echo "** previsão pluviométrica somar atualizada **"
#        mv -f "data/prev_somar_novo.csv" "data/prev_somar.csv"
#        git add "data/prev_somar.csv"
#        commit=0
#    else
#        echo "** previsão pluviométrica somar ainda não foi atualizada **"
#        rm "data/prev_somar_novo.csv"
#    fi
#else
#    echo "** erro ao recuperar previsão pluviométrica somar **"
#    error=1
#fi

if [ ! -e  "somar_prev/prev_${hoje4}.csv" ]; then
    wget "http://somarmeteorologia.com.br/security/Unesp_Cantareira/prev_${hoje4}.csv"
    if [ $? = 0 ]; then
        echo "** previsao SOMAR atualizada **"
        cp -f "prev_${hoje4}.csv" "data/prev_somar.csv"
        git add "data/prev_somar.csv"
        commit=0
        mv "prev_${hoje4}.csv" somar_prev/
    else
        echo "** previsão SOMAR ainda não foi atualizada hoje **"
    fi
fi

if [ ! "$error" = 0 ]; then
    echo "** algum erro aconteceu. Saindo sem gerar atualizações... **"
    popd
    exit $error
fi

if [[ $novo_boletim = 0 && $commit = 0 ]]; then
    #echo "Cheque os dados antes de prosseguir. Continuar? (s/n)?"
    #read check
    check="s"
    if [ ${check:0:1} = "s" ]; then
        # update.R assume que estamos em _src
        cd _src
        R --no-save < update.R
        if [ $? = 0 ]; then
            cd ..
            # "commit -a" é perigoso, lista arquivos individualmente
            git add projecoes-${hoje}.html _includes/lista_projecoes.html dados.html dados_metadata.html data/dados_de_trabalho.csv data/proj30.csv data/coefs_estimados.csv data_ocr_cor2_metadata.html historico.html index.html planilha_de_trabalho_metadata.html sitemap.xml somar_prev/projecao30_*.csv
            git commit -m "[auto] Novos dados e projeção."
            git push
        else
            error=1
            echo "** erro no script update.R **"
            cd ..
        fi
    fi
else
    echo "** Nenhum dado novo, nenhuma projeção realizada. **"
fi

popd
