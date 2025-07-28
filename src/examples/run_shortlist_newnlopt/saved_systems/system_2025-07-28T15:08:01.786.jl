# Polynomial system saved on 2025-07-28T15:08:01.787
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:08:01.786
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
    -4.118184545765999 + _t501_x2_t_,
    -0.028480628577049805 + _t501_x2ˍt_t_,
    -4.002400720141901 + _t501_x3_t_,
    -0.00048028767175337464 + _t501_x3ˍt_t_,
    -0.14240116240988343 + _t501_x1_t_,
    0.4118178734953401 + _t501_x1ˍt_t_,
    _t501_x2ˍt_t_ - _t501_x1_t_*_tpb_,
    _t501_x3ˍt_t_ - _t501_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t501_x1ˍt_t_ + _t501_x2_t_*_tpa_
]

