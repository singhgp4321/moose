import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('mesh_single_element_out.csv')

plt.figure()
plt.plot(df['strain_zz'], df['stress_zz'])
plt.xlabel('Strain (zz)')
plt.ylabel('Stress (zz) [Pa]')
plt.title('Uniaxial Stress-Strain (Single Element)')
plt.grid(True)
plt.tight_layout()
plt.savefig('stress_strain.png', dpi=150)
plt.show()
