source('ajuste_e_previsoes_para_o_site.R')
library(rmarkdown)

generate.page <- function(f, fname){
    if (missing(fname)){
        s <- strsplit(f, '.', fixed=TRUE)
        s <- s[[1]][-length(s[[1]])]
        fname <- paste(paste(s, collapse='.'), 'html', sep='.')
    }
    render(f, output_file=paste('../', fname, sep=''))
    system(paste("sed -i '1i---\\n---' ../", fname, sep=''))
}

add.projection <- function(){
    proj_file <- paste('projecoes-', fim-30, '.html', sep='')
    generate.page('previsoes.Rmd', proj_file)
    new_entry <- paste('             <li><a href="', proj_file, '">', fim-30, "</a></li>", sep='')
    write(new_entry, file="../_includes/lista_projecoes.html", append=TRUE)
    # prevent repeated entries
    system('echo "`uniq ../_includes/lista_projecoes.html`" > ../_includes/lista_projecoes.html')
}

all_files <- c('dados_metadata.Rmd', 'dados.Rmd', 'recursos.md', 'sobre.md', 'historico.Rmd')
to_update <- c('historico.Rmd', 'dados.Rmd')

#for (f in to_update){
#    generate.page(f)
#}
