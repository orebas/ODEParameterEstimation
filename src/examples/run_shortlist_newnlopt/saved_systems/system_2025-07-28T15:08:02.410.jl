# Polynomial system saved on 2025-07-28T15:08:02.410
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:08:02.410
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpbeta_
_t445_x1_t_
_t445_x2_t_
_t445_x3_t_
_t445_x2ˍt_t_
_t445_x3ˍt_t_
_t445_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpbeta_ _t445_x1_t_ _t445_x2_t_ _t445_x3_t_ _t445_x2ˍt_t_ _t445_x3ˍt_t_ _t445_x1ˍt_t_
varlist = [_tpa__tpb__tpbeta__t445_x1_t__t445_x2_t__t445_x3_t__t445_x2ˍt_t__t445_x3ˍt_t__t445_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.089344392013365 + _t445_x2_t_,
    -0.07446642780595347 + _t445_x2ˍt_t_,
    -4.002131767852524 + _t445_x3_t_,
    -0.0004802558121390632 + _t445_x3ˍt_t_,
    -0.37233213902967854 + _t445_x1_t_,
    0.4089344392013318 + _t445_x1ˍt_t_,
    _t445_x2ˍt_t_ - _t445_x1_t_*_tpb_,
    _t445_x3ˍt_t_ - _t445_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t445_x1ˍt_t_ + _t445_x2_t_*_tpa_
]

