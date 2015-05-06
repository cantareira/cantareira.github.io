#!/usr/bin/bash

ROOT="$( dirname "${BASH_SOURCE[0]}" )"
hoje=`date +"%Y-%m-%d"`
hoje2=`date +"%Y%m%d"`
ontem=`date -d "yesterday" +"%Y-%m-%d"`
commit=1
error=0

pushd "$ROOT/.."

if [ ! -e  "boletins/boletim_mananciais_${hoje}.pdf" ]; then
    wget "http://site.sabesp.com.br/site/uploads/file/boletim/boletim_mananciais.pdf"
    diff -q "boletim_mananciais.pdf" "boletins/boletim_mananciais_${ontem}.pdf"
    if [ $? != 0 ]; then
        echo "** boletim dos mananciais parece atualizado **"
        python _src/boletim_scraper.py boletim_mananciais.pdf "boletins/boletim_mananciais_${ontem}.pdf" data/dados.csv data/data_ocr_cor2.csv
        if [ $? = 0 ]; then
            mv boletim_mananciais.pdf "boletins/boletim_mananciais_${hoje}.pdf"
            git add "boletins/boletim_mananciais_${hoje}.pdf" data/dados.csv data/data_ocr_cor2.csv
            commit=0
        else
            error=1
            echo "** erro no processamento do boletim dos mananciais **"
            rm boletim_mananciais.pdf
        fi
    else
        rm "boletim_mananciais.pdf"
        echo "** boletim dos mananciais ainda não foi atualizado **"
    fi
else
    echo "** boletim dos mananciais de hoje já foi atualizado **"
fi

if [ ! -e  "SSPCJ_boletimDiario_${hoje2}.pdf" ]; then
    wget "http://www.sspcj.org.br/images/downloads/SSPCJ_boletimDiario_${hoje2}.pdf"
    if [ $? = 0 ]; then
        echo "** boletim SSPCJ parece atualizado **"
        # TODO: pdf_scraper não lida bem com boletins sem chuva
        python _src/pdf_scraper.py "SSPCJ_boletimDiario_${hoje2}.pdf" data/previsoes_boletins_pcj.csv
        if [ $? = 0 ]; then
            git add data/previsoes_boletins_pcj.csv
            commit=0
        else
            error=1
            echo "** erro no processamento do boletim SSPCJ **"
        fi
    else
        echo "** boletim SSPCJ ainda não foi atualizado **"
    fi
else
    echo "** boletim SSPCJ de hoje já foi atualizado **"
fi


if [ ! "$error" = 0 ]; then
    echo "** algum erro aconteceu. Saindo sem gerar atualizações... **"
    popd
    exit $error
fi

if [ "$commit" = 0 ]; then
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
            git add projecoes-${hoje}.html _includes/lista_projecoes.html dados.html dados_metadata.html data/dados_de_trabalho.csv data/proj30.csv data_ocr_cor2_metadata.html historico.html index.html planilha_de_trabalho_metadata.html sitemap.xml 
            git commit -m "[auto] Novos dados e projeção."
            # TODO: not yet!
            #git push
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
