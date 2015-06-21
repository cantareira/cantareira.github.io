import sys
import subprocess
import re
import os
import datetime
import calendar
from dateutil import parser
from pdf_scraper import PDF_Processor

def is_number(s, decimals=('.', ',')):
    return (len(s) and all([ x.isdigit() or x in decimals or x == '-' for x in list(s) ])
            and (s.find(',') >=0 or s.find('.') >= 0))

class Boletim_Processor(PDF_Processor):
    def __init__(self):
        pass

    def scrape_pdf(self, arquivo):
        text = subprocess.Popen(['pdftotext', '-q', '-layout', arquivo, '-'], stdout=subprocess.PIPE).communicate()[0]
        text = text.decode('utf-8') # system-dependent?
        text = re.sub('\(\d+\)\n', '', text)
        r = {}
        for l in text.split("\n"):
            # mais uma...
            l = l.replace('(9)', '').replace('(', '').replace(')', '')
            if re.search('Gerado às [0-9:]+ hs de ([0-9/]+)', l):
                g = re.search('Gerado às [0-9:]+ hs de ([0-9/]+)', l)
                r['data'] = datetime.datetime.strptime(g.groups()[0], '%d/%m/%Y').date()
            elif re.search('Cantareira +[▲▼−]( +[0-9,]+)+', l):
                r['Cantareira'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search(' +Jaguari/Jacareí ( +[0-9,]+)+', l):
                r['Jaguari'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search(' +Cachoeira ( +[0-9,]+)+', l):
                r['Cachoeira'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search(' +Atibainha  ( +[0-9,]+)+', l):
                r['Atibainha'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search(' +Paiva Castro ( +[0-9,]+)+', l):
                r['PaivaCastro'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search('Guarapiranga +( +[0-9,]+) [▲▼−] ( +[0-9,]+)+', l):
                r['Guarapiranga'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search('Rio Grande +( +[0-9,]+) [▲▼−] ( +[0-9,]+)+', l):
                r['RioGrande'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search('Rio Claro +( +[0-9,]+) [▲▼−] ( +[0-9,]+)+', l):
                r['RioClaro'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search('Alto Tietê +[▲▼−]( +[0-9,]+)+', l):
                r['AltoTiete'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search('Alto Cotia2? +[▲▼−-]( +[0-9,]+)+', l):
                r['Cotia'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search('Cantareira( +[0-9,]+)+$', l):
                r['p Cantareira'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search('Guarapiranga( +[0-9,]+)+$', l):
                r['p Guarapiranga'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search('Rio Grande( +[0-9,]+)+$', l):
                r['p RioGrande'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search('Rio Claro( +[0-9,]+)+$', l):
                r['p RioClaro'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search('Alto Tietê( +[0-9,]+)+', l):
                r['p AltoTiete'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
            elif re.search('Cotia( +[0-9,]+)+', l):
                r['p Cotia'] = [ i.replace(',', '.') for i in l.split(' ') if is_number(i) ]
 
        return r

def vline(p, vol_paivacastro):
    return '%s,%s,%s,%s,%.2f,%s,%s,%.2f,%s,%s,%.2f,%s,%s,%.1f\n' % (p['data'].strftime('%Y-%m-%d'),
            p['Jaguari'][6], p['Jaguari'][7], p['Jaguari'][2],
            float(p['Cachoeira'][4]) - float(p['Cachoeira'][6]), p['Cachoeira'][5], p['Cachoeira'][2],
            float(p['Atibainha'][6]) - float(p['Atibainha'][8]), p['Atibainha'][7], p['Atibainha'][2],
            float(p['PaivaCastro'][4]) - float(p['PaivaCastro'][6]), p['PaivaCastro'][5], p['PaivaCastro'][2],
            -((float(p['PaivaCastro'][1])-float(vol_paivacastro))*1e6/(24*3600) -
                    float(p['PaivaCastro'][4]) + float(p['PaivaCastro'][5])))

def plines(p):
    r = ''
    for s in ['Cantareira', 'AltoTiete', 'Guarapiranga', 'Cotia', 'RioGrande', 'RioClaro']:
        if s in ['Cantareira', 'AltoTiete', 'Cotia']:
            i = 1
        else:
            i = 2
        r += '"%s","%s","%s","%s","%s","%s"\n' % (p['data'].strftime('%Y-%m-%d'),
            'sistema'+s, p[s][i], p['p '+s][0], p['p '+s][1], p['p '+s][3])
    return r

def blines(p):
    r = ''
    for s in ['Cantareira', 'AltoTiete', 'Guarapiranga', 'Cotia', 'RioGrande', 'RioClaro']:
        if s in ['Cantareira', 'AltoTiete', 'Cotia']:
            i = 0
        else:
            i = 1
        j = 3
        if s == 'Cantareira':
            j = 5
        r += '"%s","%s",' % (p['data'].strftime('%Y-%m-%d'), s) + ','.join(p[s][i:i+2]+p[s][i+j:]) + '\n'
    return r

b = Boletim_Processor()
if __name__ == '__main__':
    p = b.scrape_pdf(sys.argv[1])
    pontem = b.scrape_pdf(sys.argv[2])
    if len(sys.argv) > 4:
        with open(sys.argv[3], "a") as outfile:
            outfile.write(plines(p))
        with open(sys.argv[4], "a") as outfile:
            outfile.write(vline(p, pontem['PaivaCastro'][1]))
        with open(sys.argv[5], "a") as outfile:
            outfile.write(blines(p))
    else:
        print(vline(p, pontem['PaivaCastro'][1]))
        print(plines(p))
        print(blines(p))

