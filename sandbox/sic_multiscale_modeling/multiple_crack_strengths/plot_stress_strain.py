import pandas as pd
import matplotlib.pyplot as plt

fig, ax = plt.subplots()

cases = [
    ('homogenized_block_x_out.csv', 'strain_xx', 'stress_xx', 'X-loading (Lower strength)'),
    ('homogenized_block_y_out.csv', 'strain_yy', 'stress_yy', 'Y-loading (Mid strength)'),
    ('homogenized_block_z_out.csv', 'strain_zz', 'stress_zz', 'Z-loading (Higher strength)'),
]

for csv_file, strain_col, stress_col, label in cases:
    df = pd.read_csv(csv_file)
    ax.plot(df[strain_col] * 100, df[stress_col] / 1e6, '-o', markersize=4, label=label)

ax.set_xlabel('Strain (%)')
ax.set_ylabel('Stress (MPa)')
ax.legend()
ax.set_title('Uniaxial tensile tests with direction-dependent cracking strength')
fig.savefig('stress-strain.pdf', bbox_inches='tight')
print('Saved stress-strain.pdf')

# Compare cracking-only vs cracking+plasticity for x-loading
fig2, ax2 = plt.subplots()

comparison = [
    ('homogenized_block_x_out.csv', 'Cracking only'),
    ('homogenized_block_x_ductility_out.csv', 'Cracking + plasticity'),
]

for csv_file, label in comparison:
    df = pd.read_csv(csv_file)
    ax2.plot(df['strain_xx'] * 100, df['stress_xx'] / 1e6, '-o', markersize=4, label=label)

ax2.set_xlabel('Strain (%)')
ax2.set_ylabel('Stress (MPa)')
ax2.legend()
ax2.set_title('X-loading: effect of plasticity')
fig2.savefig('stress-strain-ductility.pdf', bbox_inches='tight')
print('Saved stress-strain-ductility.pdf')
