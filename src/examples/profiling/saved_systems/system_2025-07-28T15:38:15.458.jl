# Polynomial system saved on 2025-07-28T15:38:15.458
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:38:15.458
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t201_x1_t_
_t201_x2_t_
_t201_x3_t_
_t201_x2ˍt_t_
_t201_x3ˍt_t_
_t201_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t201_x1_t_ _t201_x2_t_ _t201_x3_t_ _t201_x2ˍt_t_ _t201_x3ˍt_t_ _t201_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t201_x1_t__t201_x2_t__t201_x3_t__t201_x2ˍt_t__t201_x3ˍt_t__t201_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.180222820285738 + _t201_x2_t_^3,
    1.3904243185856762 + 3(_t201_x2_t_^2)*_t201_x2ˍt_t_,
    -7.037468811739256 + _t201_x3_t_^3,
    2.951582672731324 + 3(_t201_x3_t_^2)*_t201_x3ˍt_t_,
    -0.7121726017599896 + _t201_x1_t_^3,
    0.38540406821922457 + 3(_t201_x1_t_^2)*_t201_x1ˍt_t_,
    _t201_x2ˍt_t_ + _t201_x1_t_*_tpb_,
    _t201_x3ˍt_t_ + _t201_x1_t_*_tpc_,
    _t201_x1ˍt_t_ + _t201_x2_t_*_tpa_
]

