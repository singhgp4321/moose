#!/usr/bin/env python3

import pandas
import matplotlib.pyplot as plt

df = pandas.read_csv('faithful.csv')
fig, ax = plt.subplots()
ax.plot(df['eruptions'], df['waiting'], 'o')
plt.show()
