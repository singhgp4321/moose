import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('mesh_exp_soften_2x2_smalldt_xdir_out.csv')

plt.figure()
plt.plot(-1*df['strain_xx_dispBased'], df['stress_xx'])
plt.xlabel('Strain (xx)')
plt.ylabel('Stress (xx) [Pa]')
plt.title('Stress-Strain (Exponential Softening)')
plt.grid(True)
plt.tight_layout()
plt.savefig('stress_strain_exp_2x2_xdir.png', dpi=150)
plt.show()
