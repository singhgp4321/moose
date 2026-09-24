"""
Rotate an orthotropic elasticity tensor 45 degrees about the r-axis.

Coordinate system: r, t, y (mapped to indices 0, 1, 2)
Rotation: 45 degrees about r (index 0), so t and y rotate.
"""

import numpy as np

# Material properties (orthotropic with square symmetry - plain weave 0/90)
# r = through-thickness, t = warp (0 deg), y = weft (90 deg)
E_r = 80e9
E_t = 260e9
E_y = 260e9

nu_rt = 0.13
nu_ry = 0.13
nu_ty = 0.15

G_rt = 80e9
G_ry = 80e9
G_ty = 60e9  # Independent constant, lower than transversely isotropic value of 113 GPa

# Derived Poisson's ratios from symmetry: nu_ij * E_j = nu_ji * E_i
nu_tr = nu_rt * E_t / E_r
nu_yr = nu_ry * E_y / E_r
nu_yt = nu_ty * E_y / E_t

print("Derived Poisson's ratios:")
print(f"  nu_tr = {nu_tr:.6f}")
print(f"  nu_yr = {nu_yr:.6f}")
print(f"  nu_yt = {nu_yt:.6f}")

# Build compliance matrix S (6x6 Voigt notation)
# Voigt: 0=rr, 1=tt, 2=yy, 3=ty, 4=ry, 5=rt
S = np.zeros((6, 6))
S[0, 0] = 1.0 / E_r
S[1, 1] = 1.0 / E_t
S[2, 2] = 1.0 / E_y
S[0, 1] = -nu_tr / E_t
S[1, 0] = -nu_tr / E_t  # = -nu_rt / E_r
S[0, 2] = -nu_yr / E_y
S[2, 0] = -nu_yr / E_y  # = -nu_ry / E_r
S[1, 2] = -nu_yt / E_y
S[2, 1] = -nu_yt / E_y  # = -nu_ty / E_t
S[3, 3] = 1.0 / G_ty
S[4, 4] = 1.0 / G_ry
S[5, 5] = 1.0 / G_rt

# Stiffness matrix C = S^-1
C_voigt = np.linalg.inv(S)

print("\nOriginal stiffness matrix C (Voigt, GPa):")
print((C_voigt / 1e9).round(4))

# Check positive definiteness
eigvals = np.linalg.eigvalsh(C_voigt)
print(f"\nEigenvalues of C (GPa): {(eigvals / 1e9).round(4)}")
print(f"Positive definite: {all(eigvals > 0)}")

# Convert Voigt stiffness to full 4th-order tensor C_ijkl
# Voigt mapping: 0->00, 1->11, 2->22, 3->12, 4->02, 5->01
voigt_map = [(0, 0), (1, 1), (2, 2), (1, 2), (0, 2), (0, 1)]

C_full = np.zeros((3, 3, 3, 3))
for I in range(6):
    for J in range(6):
        i, j = voigt_map[I]
        k, l = voigt_map[J]
        C_full[i, j, k, l] = C_voigt[I, J]
        C_full[j, i, k, l] = C_voigt[I, J]
        C_full[i, j, l, k] = C_voigt[I, J]
        C_full[j, i, l, k] = C_voigt[I, J]

# Rotation matrix: 45 degrees about r-axis (index 0)
# t and y rotate, r stays fixed
theta = np.radians(45)
c, s = np.cos(theta), np.sin(theta)
R = np.array([
    [1,  0, 0],
    [0,  c, s],
    [0, -s, c]
])

print(f"\nRotation matrix (45 deg about r):")
print(R.round(6))

# Rotate: C'_ijkl = R_im R_jn R_kp R_lq C_mnpq
C_rot = np.einsum('im,jn,kp,lq,mnpq->ijkl', R, R, R, R, C_full)

# Convert back to Voigt notation
C_rot_voigt = np.zeros((6, 6))
for I in range(6):
    for J in range(6):
        i, j = voigt_map[I]
        k, l = voigt_map[J]
        C_rot_voigt[I, J] = C_rot[i, j, k, l]

print("\nRotated stiffness matrix C' (Voigt, GPa):")
np.set_printoptions(precision=4, suppress=True, linewidth=120)
print((C_rot_voigt / 1e9).round(4))

# Extract engineering constants from rotated compliance
S_rot = np.linalg.inv(C_rot_voigt)

E_r_rot = 1.0 / S_rot[0, 0]
E_t_rot = 1.0 / S_rot[1, 1]
E_y_rot = 1.0 / S_rot[2, 2]
G_ty_rot = 1.0 / S_rot[3, 3]
G_ry_rot = 1.0 / S_rot[4, 4]
G_rt_rot = 1.0 / S_rot[5, 5]
nu_rt_rot = -S_rot[0, 1] * E_r_rot
nu_ry_rot = -S_rot[0, 2] * E_r_rot
nu_ty_rot = -S_rot[1, 2] * E_t_rot

print("\nRotated engineering constants:")
print(f"  E_r'  = {E_r_rot / 1e9:.4f} GPa")
print(f"  E_t'  = {E_t_rot / 1e9:.4f} GPa")
print(f"  E_y'  = {E_y_rot / 1e9:.4f} GPa")
print(f"  G_rt' = {G_rt_rot / 1e9:.4f} GPa")
print(f"  G_ry' = {G_ry_rot / 1e9:.4f} GPa")
print(f"  G_ty' = {G_ty_rot / 1e9:.4f} GPa")
print(f"  nu_rt' = {nu_rt_rot:.6f}")
print(f"  nu_ry' = {nu_ry_rot:.6f}")
print(f"  nu_ty' = {nu_ty_rot:.6f}")

# Check if the rotated tensor has significant off-diagonal coupling
# (Voigt entries that are zero for orthotropic but nonzero after rotation)
print("\nOff-diagonal coupling terms in rotated C' (GPa):")
print(f"  C'_14 (rr-ty) = {C_rot_voigt[0, 3] / 1e9:.4f}")
print(f"  C'_15 (rr-ry) = {C_rot_voigt[0, 4] / 1e9:.4f}")
print(f"  C'_16 (rr-rt) = {C_rot_voigt[0, 5] / 1e9:.4f}")
print(f"  C'_24 (tt-ty) = {C_rot_voigt[1, 3] / 1e9:.4f}")
print(f"  C'_25 (tt-ry) = {C_rot_voigt[1, 4] / 1e9:.4f}")
print(f"  C'_34 (yy-ty) = {C_rot_voigt[2, 3] / 1e9:.4f}")
print(f"  C'_35 (yy-ry) = {C_rot_voigt[2, 4] / 1e9:.4f}")
print(f"  C'_45 (ty-ry) = {C_rot_voigt[3, 4] / 1e9:.4f}")
print(f"  C'_46 (ty-rt) = {C_rot_voigt[3, 5] / 1e9:.4f}")
print(f"  C'_56 (ry-rt) = {C_rot_voigt[4, 5] / 1e9:.4f}")
