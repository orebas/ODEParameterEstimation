# Polynomial system saved on 2025-07-28T15:08:02.476
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:08:02.476
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpbeta_
_t501_x1_t_
_t501_x2_t_
_t501_x3_t_
_t501_x2ˍt_t_
_t501_x3ˍt_t_
_t501_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpbeta_ _t501_x1_t_ _t501_x2_t_ _t501_x3_t_ _t501_x2ˍt_t_ _t501_x3ˍt_t_ _t501_x1ˍt_t_
varlist = [_tpa__tpb__tpbeta__t501_x1_t__t501_x2_t__t501_x3_t__t501_x2ˍt_t__t501_x3ˍt_t__t501_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.118184530958026 + _t501_x2_t_,
    -0.028480227870637975 + _t501_x2ˍt_t_,
    -4.002400720144019 + _t501_x3_t_,
    -0.000480288086416536 + _t501_x3ˍt_t_,
    -0.14240113935290807 + _t501_x1_t_,
    0.41181845309579046 + _t501_x1ˍt_t_,
    _t501_x2ˍt_t_ - _t501_x1_t_*_tpb_,
    _t501_x3ˍt_t_ - _t501_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t501_x1ˍt_t_ + _t501_x2_t_*_tpa_
]

