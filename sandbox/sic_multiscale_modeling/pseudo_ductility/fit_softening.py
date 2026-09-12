import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# ============================================================
# Tunable parameters -- adjust these and re-run to fit
# ============================================================

# Axial (zz) direction
beta_zz = 0.01
residual_stress_zz = 200.0          # [Pa]
cracking_stress_zz = 100e6       # [Pa]
youngs_modulus_zz = 400e9         # [Pa]

# Transverse (xx) direction
beta_xx = 1.0
residual_stress_xx = 50.0          # [Pa]
cracking_stress_xx = 175e6       # [Pa]
youngs_modulus_xx = 400e9         # [Pa]

# ============================================================
# Analytical exponential softening model
# ============================================================

def exponential_softening(strain, E, sigma_cr, beta, sigma_res):
    """Evaluate the exponential softening stress-strain curve.

    For strain < eps_init:  sigma = E * strain           (elastic)
    For strain >= eps_init: sigma = sigma_cr * [r + (1-r) * exp(-E*beta/sigma_cr * (strain - eps_init))]

    where eps_init = sigma_cr / E  and  r = sigma_res / sigma_cr.
    """
    eps_init = sigma_cr / E
    r = sigma_res / sigma_cr
    stress = np.where(
        strain < eps_init,
        E * strain,
        sigma_cr * (r + (1.0 - r) * np.exp(-E * beta / sigma_cr * (strain - eps_init))),
    )
    return stress

# ============================================================
# Load target data
# ============================================================

df_zz = pd.read_csv('mesh_exp_soften_2x2_smalldt_out.csv')
strain_zz_target = -1 * df_zz['strain_zz_dispBased'].values
stress_zz_target = df_zz['stress_zz'].values

df_xx = pd.read_csv('mesh_exp_soften_2x2_smalldt_xdir_out.csv')
strain_xx_target = -1 * df_xx['strain_xx_dispBased'].values
stress_xx_target = df_xx['stress_xx'].values

# ============================================================
# Evaluate analytical curves
# ============================================================

eps_zz = np.linspace(0, strain_zz_target.max(), 500)
sig_zz = exponential_softening(eps_zz, youngs_modulus_zz, cracking_stress_zz,
                               beta_zz, residual_stress_zz)

eps_xx = np.linspace(0, strain_xx_target.max(), 500)
sig_xx = exponential_softening(eps_xx, youngs_modulus_xx, cracking_stress_xx,
                               beta_xx, residual_stress_xx)

# ============================================================
# Plot
# ============================================================

fig, axes = plt.subplots(1, 2, figsize=(12, 5))

# Axial (zz)
ax = axes[0]
ax.plot(strain_zz_target, stress_zz_target / 1e6, 'k-', label='Target (micro-scale)')
ax.plot(eps_zz, sig_zz / 1e6, 'r--',
        label=f'Fit (β={beta_zz}, σ_res={residual_stress_zz/1e6:.1f} MPa)')
ax.set_xlabel('Strain (zz)')
ax.set_ylabel('Stress (zz) [MPa]')
ax.set_title('Axial direction')
ax.legend()
ax.grid(True)

# Transverse (xx)
ax = axes[1]
ax.plot(strain_xx_target, stress_xx_target / 1e6, 'k-', label='Target (micro-scale)')
ax.plot(eps_xx, sig_xx / 1e6, 'r--',
        label=f'Fit (β={beta_xx}, σ_res={residual_stress_xx/1e6:.1f} MPa)')
ax.set_xlabel('Strain (xx)')
ax.set_ylabel('Stress (xx) [MPa]')
ax.set_title('Transverse direction')
ax.legend()
ax.grid(True)

fig.suptitle('Exponential Softening Calibration')
fig.tight_layout()
fig.savefig('fit_softening.png', dpi=150)
plt.show()
