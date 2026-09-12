import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('mesh_exp_soften_4x4_smalldt_out.csv')

plt.figure()
plt.plot(-1*df['strain_zz_dispBased'], df['stress_zz'])
plt.xlabel('Strain (zz)')
plt.ylabel('Stress (zz) [Pa]')
plt.title('Stress-Strain (Exponential Softening)')
plt.grid(True)
plt.tight_layout()
plt.savefig('stress_strain_exp_4x4.png', dpi=150)
plt.show()
