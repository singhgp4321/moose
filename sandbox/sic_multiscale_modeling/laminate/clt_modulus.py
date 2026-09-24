"""
Classical Lamination Theory (CLT) estimation of effective Young's modulus
for the two-layer laminate in laminate_two_layers.i.

Laminate stacking direction: y (= r, through-thickness)
Laminate plane: x-z (= t-y_user, in-plane)
Loading: uniaxial stress along z

Layer 1 (bottom): 0/90 plain weave, orthotropic
Layer 2 (top):    same weave rotated 45 deg about r (= y)

CLT assumes plane stress in the laminate plane (sigma_yy = 0),
uniform in-plane strains (epsilon_xx, epsilon_zz, gamma_xz) through thickness.
"""

import numpy as np

# ---- Build 3D stiffness matrices in mesh coordinates (x=t, y=r, z=y_user) ----
# Voigt ordering used here: 0=xx, 1=yy, 2=zz, 3=yz, 4=xz, 5=xy
# This is the standard Voigt convention matching MOOSE

# Re-derive both stiffness matrices from the rotation script
# Material properties (plain weave 0/90)
E_r = 80e9;   E_t = 260e9;  E_y = 260e9
nu_rt = 0.13; nu_ry = 0.13; nu_ty = 0.15
G_rt = 80e9;  G_ry = 80e9;  G_ty = 60e9

# Derived Poisson's ratios
nu_tr = nu_rt * E_t / E_r  # 0.4225
nu_yr = nu_ry * E_y / E_r  # 0.4225
nu_yt = nu_ty              # E_t = E_y, so nu_yt = nu_ty

# Compliance in material coords (r, t, y) with Voigt: 0=rr, 1=tt, 2=yy
S_mat = np.zeros((6, 6))
S_mat[0, 0] = 1.0 / E_r
S_mat[1, 1] = 1.0 / E_t
S_mat[2, 2] = 1.0 / E_y
S_mat[0, 1] = S_mat[1, 0] = -nu_tr / E_t
S_mat[0, 2] = S_mat[2, 0] = -nu_yr / E_y
S_mat[1, 2] = S_mat[2, 1] = -nu_yt / E_y
S_mat[3, 3] = 1.0 / G_ty
S_mat[4, 4] = 1.0 / G_ry
S_mat[5, 5] = 1.0 / G_rt

C_mat = np.linalg.inv(S_mat)  # 3D stiffness in (r, t, y)

# Reorder from (r, t, y) to mesh (x, y, z) = (t, r, y_user)
# Material index:  r=0, t=1, y=2
# Mesh index:      x=1, y=0, z=2  (i.e., mesh_x = mat_t, mesh_y = mat_r, mesh_z = mat_y)
# So permutation: mesh 0(x) <- mat 1(t), mesh 1(y) <- mat 0(r), mesh 2(z) <- mat 2(y)

# Voigt reordering: mat (rr,tt,yy,ty,ry,rt) -> mesh (xx,yy,zz,yz,xz,xy)
# mat 0(rr) -> mesh 1(yy), mat 1(tt) -> mesh 0(xx), mat 2(yy) -> mesh 2(zz)
# mat 3(ty) -> mesh 3(yz)... need to be careful with shear mapping
# Shear pairs: mat ty(12)->mesh xz? No.
# mat t=mesh_x, mat y=mesh_z => mat ty = mesh xz => Voigt 4
# mat r=mesh_y, mat y=mesh_z => mat ry = mesh yz => Voigt 3
# mat r=mesh_y, mat t=mesh_x => mat rt = mesh xy => Voigt 5
# So: mat Voigt (0,1,2,3,4,5) = (rr,tt,yy,ty,ry,rt)
#  -> mesh Voigt: rr->yy(1), tt->xx(0), yy->zz(2), ty->xz(4), ry->yz(3), rt->xy(5)
# Permutation: p = [1, 0, 2, 4, 3, 5]

p = [1, 0, 2, 4, 3, 5]
C_layer1 = C_mat[np.ix_(p, p)]

print("Layer 1 stiffness (mesh coords, GPa):")
print((C_layer1 / 1e9).round(4))

# ---- Rotate for Layer 2 ----
# Rotation is 45 deg about r-axis (= mesh y-axis)
# Work with the full 4th-order tensor in mesh coordinates, then rotate

voigt_map = [(0, 0), (1, 1), (2, 2), (1, 2), (0, 2), (0, 1)]

def voigt_to_full(C_v):
    C_f = np.zeros((3, 3, 3, 3))
    for I in range(6):
        for J in range(6):
            i, j = voigt_map[I]
            k, l = voigt_map[J]
            C_f[i, j, k, l] = C_v[I, J]
            C_f[j, i, k, l] = C_v[I, J]
            C_f[i, j, l, k] = C_v[I, J]
            C_f[j, i, l, k] = C_v[I, J]
    return C_f

def full_to_voigt(C_f):
    C_v = np.zeros((6, 6))
    for I in range(6):
        for J in range(6):
            i, j = voigt_map[I]
            k, l = voigt_map[J]
            C_v[I, J] = C_f[i, j, k, l]
    return C_v

C1_full = voigt_to_full(C_layer1)

# Rotation 45 deg about mesh y-axis: x and z rotate, y stays
theta = np.radians(45)
c, s = np.cos(theta), np.sin(theta)
R = np.array([
    [ c, 0, s],
    [ 0, 1, 0],
    [-s, 0, c]
])

C2_full = np.einsum('im,jn,kp,lq,mnpq->ijkl', R, R, R, R, C1_full)
C_layer2 = full_to_voigt(C2_full)

print("\nLayer 2 stiffness (mesh coords, GPa):")
print((C_layer2 / 1e9).round(4))

# ---- CLT: Plane-stress reduction ----
# Laminate plane is x-z, stacking along y.
# Plane stress: sigma_yy = sigma_xy = sigma_yz = 0
# In-plane Voigt indices (xx, zz, xz) correspond to full Voigt (0, 2, 4)
# Out-of-plane Voigt indices (yy, yz, xy) correspond to full Voigt (1, 3, 5)

ip = [0, 2, 4]   # in-plane: xx, zz, xz
op = [1, 3, 5]   # out-of-plane: yy, yz, xy

def plane_stress_reduce(C):
    """Reduce 6x6 3D stiffness to 3x3 plane-stress stiffness (laminate plane x-z).

    sigma_op = 0  =>  eps_op = -C_oo^{-1} C_oi eps_ip
    sigma_ip = (C_ii - C_io C_oo^{-1} C_oi) eps_ip = Q eps_ip
    """
    C_ii = C[np.ix_(ip, ip)]
    C_io = C[np.ix_(ip, op)]
    C_oi = C[np.ix_(op, ip)]
    C_oo = C[np.ix_(op, op)]
    Q = C_ii - C_io @ np.linalg.inv(C_oo) @ C_oi
    return Q

Q1 = plane_stress_reduce(C_layer1)
Q2 = plane_stress_reduce(C_layer2)

print("\nReduced stiffness Q1 (layer 1, GPa):")
print((Q1 / 1e9).round(4))
print("\nReduced stiffness Q2 (layer 2, GPa):")
print((Q2 / 1e9).round(4))

# ---- CLT A-matrix (extensional stiffness) ----
# Equal thickness layers: h1 = h2 = h/2, total thickness h
# A = sum(Q_k * t_k) = (Q1 + Q2) * h/2
# For effective properties, use A* = A / h = (Q1 + Q2) / 2

A_star = (Q1 + Q2) / 2.0  # Effective in-plane stiffness

print("\nEffective in-plane stiffness A* = (Q1+Q2)/2 (GPa):")
print((A_star / 1e9).round(4))

# ---- Effective engineering constants ----
# A* relates (sigma_xx_avg, sigma_zz_avg, tau_xz_avg) to (eps_xx, eps_zz, gamma_xz)
# Compliance: a* = (A*)^{-1}
a_star = np.linalg.inv(A_star)

# In-plane indices: 0=xx, 1=zz, 2=xz
E_x_eff = 1.0 / a_star[0, 0]
E_z_eff = 1.0 / a_star[1, 1]
G_xz_eff = 1.0 / a_star[2, 2]
nu_xz_eff = -a_star[0, 1] * E_x_eff
nu_zx_eff = -a_star[0, 1] * E_z_eff

print("\n" + "="*60)
print("CLT effective in-plane properties:")
print(f"  E_x  = {E_x_eff / 1e9:.4f} GPa")
print(f"  E_z  = {E_z_eff / 1e9:.4f} GPa  (loading direction)")
print(f"  G_xz = {G_xz_eff / 1e9:.4f} GPa")
print(f"  nu_xz = {nu_xz_eff:.6f}")
print(f"  nu_zx = {nu_zx_eff:.6f}")
print("="*60)

# ---- Comparison ----
E_z_avg = (260e9 + 172.4e9) / 2  # Simple rule-of-mixtures
print(f"\nSimple average E_z = {E_z_avg / 1e9:.1f} GPa")
print(f"CLT E_z          = {E_z_eff / 1e9:.4f} GPa")
print(f"FEA result        ~ 212 GPa")

# Also check: what is E_z for each layer individually (plane stress)?
a1 = np.linalg.inv(Q1)
a2 = np.linalg.inv(Q2)
E_z_layer1_ps = 1.0 / a1[1, 1]
E_z_layer2_ps = 1.0 / a2[1, 1]
print(f"\nPlane-stress E_z, layer 1 = {E_z_layer1_ps / 1e9:.4f} GPa")
print(f"Plane-stress E_z, layer 2 = {E_z_layer2_ps / 1e9:.4f} GPa")
print(f"Average of plane-stress E_z = {(E_z_layer1_ps + E_z_layer2_ps) / 2e9:.4f} GPa")
