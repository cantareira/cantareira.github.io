#!/usr/bin/bash

baseurl="http://cantareira.github.io/"
header='<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
footer="</urlset>"

daily_pages=("index.html")

# helper function
containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && echo "y"; return 0; done
  return 1
}

pushd ..
content=""
for i in *html
do
    extra=""
    if [ "$(containsElement "$i" "${daily_pages[@]}")" == "y" ]
    then
        extra="    <changefreq>daily</changefreq>\n"
    fi
    content="$content  <url>\n    <loc>${baseurl}${i}</loc>\n$extra  </url>\n"
done

echo -e "$header\n$content\n$footer" > sitemap.xml

popd
