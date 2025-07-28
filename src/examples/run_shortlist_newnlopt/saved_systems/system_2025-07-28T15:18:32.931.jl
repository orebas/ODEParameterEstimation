# Polynomial system saved on 2025-07-28T15:18:32.932
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:18:32.931
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t445_x1_t_
_t445_x2_t_
_t445_x1ˍt_t_
_t445_x2ˍt_t_
_t501_x1_t_
_t501_x2_t_
_t501_x1ˍt_t_
_t501_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t445_x1_t_ _t445_x2_t_ _t445_x1ˍt_t_ _t445_x2ˍt_t_ _t501_x1_t_ _t501_x2_t_ _t501_x1ˍt_t_ _t501_x2ˍt_t_
varlist = [_tpa__tpb__t445_x1_t__t445_x2_t__t445_x1ˍt_t__t445_x2ˍt_t__t501_x1_t__t501_x2_t__t501_x1ˍt_t__t501_x2ˍt_t_]

# Polynomial System
poly_system = [
    4.727778950853626 + 3.0_t445_x1_t_ - 0.25_t445_x2_t_,
    3.6738500137337264 + 2.0_t445_x1_t_ + 0.5_t445_x2_t_,
    0.030073649084638242 + 2.0_t445_x1ˍt_t_ + 0.5_t445_x2ˍt_t_,
    _t445_x1ˍt_t_ + _t445_x2_t_*_tpa_,
    _t445_x2ˍt_t_ - _t445_x1_t_*_tpb_,
    3.7943653367692156 + 3.0_t501_x1_t_ - 0.25_t501_x2_t_,
    3.5076082513483273 + 2.0_t501_x1_t_ + 0.5_t501_x2_t_,
    -0.6188196290194202 + 2.0_t501_x1ˍt_t_ + 0.5_t501_x2ˍt_t_,
    _t501_x1ˍt_t_ + _t501_x2_t_*_tpa_,
    _t501_x2ˍt_t_ - _t501_x1_t_*_tpb_
]

