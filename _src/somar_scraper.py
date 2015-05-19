import requests
import re
import datetime
import numpy

def scrape_data(sistema='Cantareira'):
    url = "http://iframe.somarmeteorologia.com.br/mananciais/"
    text = requests.post(url, data={'sistema': sistema}).text
    
    g1 = re.search("categories: \[([^\]]+)\]", text, re.DOTALL)
    dates = [ datetime.datetime.strptime(i, "'%d/%m/%Y'").date()  for i in g1.groups()[0].split(',') if i != '' ]
    
    pattern = "name: 'Previsão \(mm\)',\s+type: 'column',\s+color: '#\w+',\s+data: \[([^\]]+)\]"
    g2 = re.search(pattern, text, re.DOTALL)
    pluv = [ int(i.strip("'")) for i in g2.groups()[0].split(',') if i != '' ]
    
    # estranhamente, os dados nem sempre têm o mesmo comprimento
    pluv = pluv[:len(dates)]
    dates = dates[:len(pluv)]
    
    r = numpy.array([dates, pluv]).T
    # filtrando datas passadas
    r = r[r[:,0] >= datetime.date.today()]
    return r

if __name__ == '__main__':
    import sys
    r = scrape_data(sys.argv[1])
    if len(r) == 0:
        sys.exit(1)
    if len(sys.argv) > 2:
        numpy.savetxt(sys.argv[2], r, fmt=['"%s"', '%d'], delimiter=",",
                header='"data","pluviometria"', comments='')
    else:
        print("previsão para o sistema %s" % sys.argv[1])
        print(r)
