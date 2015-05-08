#!/usr/bin/bash

cd ../boletins

output=""
for i in *.pdf
do
    fim=${i#boletim_mananciais_}
    data=`date -d "${fim%.pdf}" +"%d de %B de %Y"`
    output="${output}  <li><a href=\"/boletins/$i\">Boletim Mananciais $data</a></li>\n"
done

echo -e $output
