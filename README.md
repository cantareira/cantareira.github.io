# cantareira.github.io #

Arquivos-fonte do site `cantareira.github.io`.

## Instruções de instalação e configuração. ##

### R ###
Pacotes;
* rmarkdown
* dygraphs
* deSolve
* devtools
* pomp versão de desenvolvimento, via:

    devtools::install_github('rforge/pomp', subdir='pkg/pomp')
* outros...

### Jekyll ###
* ruby
* gem (geralmente é instalado junto com ruby)
* nodejs (ou outro interpretador JS)
* Jekyll, via gem:

    gem install 'github-pages'

Isso deve criar uma instalação local (na pasta do usuário), tipicamente em `$USER/.gem/ruby/`. Por praticidade, criamos um alias:
    
    alias jekyll='~/.gem/ruby/2.2.0/bin/jekyll'

Esta forma de instalar Jekyll não é a mais recomendada porque não garante que a
versão de Jekyll local é à mesma usada pelo github, mas deve ser suficiente
para nossos requisitos, que nsão mínimos.

### Fontes do site ###
* clone do repositório com as fontes:

    git clone git@github.com:cantareira/cantareira.github.io.git

As fontes contêm os htmls já processados pelo rmarkdown, mas não a saída do
Jekyll, que é realizada pelo próprio github.

* atualizações periódicas são feitas rodando o script `update.R`, que atualiza o histórico e cria uma nova página de projeções.

* novas páginas são feitas adicionando os arquivos Rmd, gerando os htmls via `render('arquivo.Rmd')` no shell do `R`, e adicionando um cabeçalho do YAML:
    sed -i '1i---\n---' arquivo.html arquivo2.html

* o conteúdo adicionado pode ser visualizado rodando

    jekyll build
    jekyll serve

O default é o site ser servido em `http://localhost:4000`.

* Finalmente, o conteúdo novo é publicado quando fazemos o commit e enviamos pro repositório `cantareira` no github.

