# Polynomial system saved on 2025-07-28T15:17:10.890
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:10.890
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t501_C1_t_
_t501_C2_t_
_t501_C1ˍt_t_
_t501_C1ˍtt_t_
_t501_C1ˍttt_t_
_t501_C2ˍt_t_
_t501_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t501_C1_t_ _t501_C2_t_ _t501_C1ˍt_t_ _t501_C1ˍtt_t_ _t501_C1ˍttt_t_ _t501_C2ˍt_t_ _t501_C2ˍtt_t_
varlist = [_tpk21__tpke__t501_C1_t__t501_C2_t__t501_C1ˍt_t__t501_C1ˍtt_t__t501_C1ˍttt_t__t501_C2ˍt_t__t501_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -0.3100987681597581 + _t501_C1_t_,
    0.013581274278615036 + _t501_C1ˍt_t_,
    -0.0006082453158147466 + _t501_C1ˍtt_t_,
    -0.00017862370418160757 + _t501_C1ˍttt_t_,
    0.2556079224553873_t501_C1_t_ + _t501_C1ˍt_t_ + _t501_C1_t_*_tpke_ - 0.5730452997295079_t501_C2_t_*_tpk21_,
    0.2556079224553873_t501_C1ˍt_t_ + _t501_C1ˍtt_t_ + _t501_C1ˍt_t_*_tpke_ - 0.5730452997295079_t501_C2ˍt_t_*_tpk21_,
    0.2556079224553873_t501_C1ˍtt_t_ + _t501_C1ˍttt_t_ + _t501_C1ˍtt_t_*_tpke_ - 0.5730452997295079_t501_C2ˍtt_t_*_tpk21_,
    -0.44605186112867656_t501_C1_t_ + _t501_C2ˍt_t_ + _t501_C2_t_*_tpk21_,
    -0.44605186112867656_t501_C1ˍt_t_ + _t501_C2ˍtt_t_ + _t501_C2ˍt_t_*_tpk21_
]

