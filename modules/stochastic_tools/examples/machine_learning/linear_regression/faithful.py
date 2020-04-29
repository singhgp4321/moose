#!/usr/bin/env python3

import pandas
import matplotlib.pyplot as plt
import numpy as np

df = pandas.read_csv('faithful.csv')
fig, ax = plt.subplots()
ax.plot(df['eruptions'], df['waiting'], 'o')

slope = 3.22447953586104319e+01
intercept = 1.10481975077917483e+01
x = np.linspace(df['eruptions'].min(), df['eruptions'].max(), 50)
y = slope + x * intercept
ax.plot(x, y, '--k')

plt.show()
