# -*- coding: utf-8 -*-
# este script depende de pdftotext do sistema, além das bibliotecas em python abaixo
import sys
import subprocess
import re
import pycurl
import os
import datetime
import calendar
from dateutil import parser

def daterange(start_date, end_date):
    '''Returns range of dates between start and end, inclusive.'''
    for n in range(int ((end_date - start_date).days) + 1):
        yield start_date + datetime.timedelta(n)

meses = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho',
         'agosto', 'setembro', 'outubro', 'novembro', 'dezembro']
def translate_month(s):
    for i in range(12):
        s = s.replace(meses[i], calendar.month_name[i+1])
    return s

class PDF_Processor(object):
    def __init__(self, urlformat, targets):
        self.urlformat = urlformat
        self.targets = targets

    def scrape_pdf(self, arquivo, NA=''):
        text = subprocess.Popen(["pdftotext", "-q", arquivo, "-"], stdout=subprocess.PIPE).communicate()[0]
        text = text.decode('utf-8') # system-dependent?
        text = text.replace("\n", ' ')
        r = []
        for target, pattern, transform in self.targets:
            v = re.search(pattern, text)
            if v:
                r.append(transform(v.groups()))
            else:
                r.append(NA)
        return r

    def get_file(self, address):
        # As long as the file is opened in binary mode, both Python 2 and Python 3
        # can write response body to it without decoding.
        fname = address.split('/')[-1]
        with open(fname, 'wb') as f:
            c = pycurl.Curl()
            c.setopt(c.URL, address)
            c.setopt(c.WRITEDATA, f)
            c.perform()
            c.close()
    
        return fname

    def process_date(self, date):
        f = self.get_file(self.urlformat.format(year=date.year,
            month=date.month, day=date.day))
        r = self.scrape_pdf(f)
        os.remove(f)
        return r

    def process_daterange(self, start, end):
        r = []
        dr = list(daterange(start, end))
        for date in dr:
            r.append([date] + self.process_date(date))
            print('.', end='')
        return r

# retira do boletim diário da ANA as vazões afluentes e defluentes do SE e
# Paiva Castro, e QESI
# status: OK! Falta comparar e manter uma tabela atualizada.
patterns = ['Qaflu-SE = (\d+),(\d+)',
            'Qdeflu-SE = (\d+),(\d+)m',
            'Qaflu-PC = (\d+),(\d+)m',
            'Qdeflu-PC = (\d+),(\d+)m',
            'Q-T5 = (\d+),(\d+)m',
            'Q-EESI = (\d+),(\d+)m']
def transform(v):
    return int(v[0]) + int(v[1])/100.
targets = [(p.split(' ')[0], p, transform) for p in patterns]
url = ("http://arquivos.ana.gov.br/saladesituacao/BoletinsDiarios/"
       "DivulgacaoSiteSabesp_{day:d}-{month:d}-{year:d}.pdf")
vazoes_ANA = PDF_Processor(url, tuple(targets))

# retira do boletim diário do SSPCJ as previsões de chuvas de 5 dias
# status: parece funcionar, ainda não é (e talvez nunca será) robusto
url = ("http://www.sspcj.org.br/images/downloads/SSPCJ_boletimDiario_"
       "{year:d}{month:02d}{day:02d}.pdf")
def transform(v):
    v = list(v)
    v[0] = parser.parse(translate_month(v[0]), fuzzy=True)
    v[1] = parser.parse(translate_month(v[1]), fuzzy=True)
    v[2] = int(v[2])
    v[3] = int(v[3])
    return v
def transform_semchuva(v):
    d1 = parser.parse(translate_month(v[0]), fuzzy=True)
    d2 = parser.parse(translate_month(v[1]), fuzzy=True)
    return [d1, d2, 0, 0]
    
targets = [('prev', ('A +previsão +de +chuvas +entre +os +dias +(.+) +a +(.+)'
           ' +é +de +acumulados +de +(\d+) +a +(\d+) +mm +nas +Bacias +PCJ.'),
           transform),
           ('noprev', ('Não +há +previsão +de +chuvas +entre +os +dias +(.+) a +(.+)'
               ' +nas +Bacias +PCJ.'), transform_semchuva)]
previsao_chuva_SABESP = PDF_Processor(url, tuple(targets))

def pline(p):
    return '"%s","%s",%d,%d\n' % (p[0].strftime('%Y-%m-%d'),
           p[1].strftime('%Y-%m-%d'), p[2], p[3])

if __name__ == '__main__':
    p = previsao_chuva_SABESP.scrape_pdf(sys.argv[1])
    p = [ i for i in p if i != '' ][0]
    if len(sys.argv) > 2:
        with open(sys.argv[2], "a") as outfile:
            outfile.write(pline(p))
    else:
        print(pline(p))

