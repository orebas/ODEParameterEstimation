# Polynomial system saved on 2025-07-28T15:14:01.154
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:14:01.154
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t445_x1_t_
_t445_x2_t_
_t445_x3_t_
_t445_x2ˍt_t_
_t445_x3ˍt_t_
_t445_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t445_x1_t_ _t445_x2_t_ _t445_x3_t_ _t445_x2ˍt_t_ _t445_x3ˍt_t_ _t445_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t445_x1_t__t445_x2_t__t445_x3_t__t445_x2ˍt_t__t445_x3ˍt_t__t445_x1ˍt_t_]

# Polynomial System
poly_system = [
    -5.053644373589201 + _t445_x2_t_^3,
    1.7424243795825503 + 3(_t445_x2_t_^2)*_t445_x2ˍt_t_,
    -8.92260856202153 + _t445_x3_t_^3,
    3.818003899102472 + 3(_t445_x3_t_^2)*_t445_x3ˍt_t_,
    -0.9589571741259704 + _t445_x1_t_^3,
    0.5006363640033403 + 3(_t445_x1_t_^2)*_t445_x1ˍt_t_,
    _t445_x2ˍt_t_ + _t445_x1_t_*_tpb_,
    _t445_x3ˍt_t_ + _t445_x1_t_*_tpc_,
    _t445_x1ˍt_t_ + _t445_x2_t_*_tpa_
]

