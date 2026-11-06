import pandas as pd
import matplotlib.pyplot as plt

fig, ax = plt.subplots()

cases = [
    ('homogenized_block_x_ductility_out.csv', 'strain_xx', 'stress_xx', 'X-loading'),
    ('homogenized_block_y_ductility_out.csv', 'strain_yy', 'stress_yy', 'Y-loading'),
]

for csv_file, strain_col, stress_col, label in cases:
    df = pd.read_csv(csv_file)
    ax.plot(df[strain_col] * 100, df[stress_col] / 1e6, '-', markersize=4, label=label)

ax.set_xlabel('Strain (%)')
ax.set_ylabel('Stress (MPa)')
ax.legend()
ax.set_title('Cracking + plasticity: X vs Y loading')
fig.savefig('stress-strain-ductility.pdf', bbox_inches='tight')
print('Saved stress-strain-ductility.pdf')

# Randomized strengths
fig2, ax2 = plt.subplots()

random_cases = [
    ('homogenized_block_x_ductility_randomizedStrength_out.csv', 'strain_xx', 'stress_xx', 'X-loading'),
    ('homogenized_block_y_ductility_randomizedStrength_out.csv', 'strain_yy', 'stress_yy', 'Y-loading'),
]

for csv_file, strain_col, stress_col, label in random_cases:
    df = pd.read_csv(csv_file)
    ax2.plot(df[strain_col] * 100, df[stress_col] / 1e6, '-', markersize=4, label=label)

ax2.set_xlabel('Strain (%)')
ax2.set_ylabel('Stress (MPa)')
ax2.legend()
ax2.set_title('Cracking + plasticity: randomized strengths')
fig2.savefig('stress-strain-ductility-randomized.pdf', bbox_inches='tight')
print('Saved stress-strain-ductility-randomized.pdf')
