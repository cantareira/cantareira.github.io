from glob import glob
import re
import pandas as pd

def resgata_projecoes(ff):
    pattern = re.compile('''
<th align="center">Projeção</th>
<th align="center">Limite inferior</th>
<th align="center">Limite superior</th>
<tbody>
<tr class="odd">
<td align="center">75% da média</td>
<td align="center">([0-9,]+)</td>
<td align="center">([0-9,]+)</td>
<td align="center">([0-9,]+)</td>
<tr class="even">
<td align="center">Na média</td>
<td align="center">([0-9,]+)</td>
<td align="center">([0-9,]+)</td>
<td align="center">([0-9,]+)</td>
<tr class="odd">
<td align="center">125% da média</td>
<td align="center">([0-9,]+)</td>
<td align="center">([0-9,]+)</td>
<td align="center">([0-9,]+)</td>
''', flags=re.MULTILINE|re.UNICODE)
    
    allm = []
    
    for f in ff:
        r = ''.join([ s for s in open(f, 'r').readlines() if s[:2] == '<t' ])
        m = pattern.findall(r)
        if len(m) > 0:
            m = [ float(mi.replace(',', '.')) for mi in m[0] ]
            allm.append([f[-15:-5]] + m)
        else:
            print(f)
    
    df = pd.DataFrame(data=allm, columns=['data', 'proj75', 'inf75', 'sup75', 'proj100', 'inf100', 'sup100', 'proj125', 'inf125', 'sup125'])
    df.data = pd.to_datetime(df.data)
    return df

if __name__ == '__main__':
    ff = glob('../projecoes-*.html')
    ff.sort()
    df = resgata_projecoes(ff)
    df.to_csv('sumario-projecoes.csv')

