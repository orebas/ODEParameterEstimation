# Polynomial system saved on 2025-07-28T15:14:03.455
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:14:03.455
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
    -5.053644512684008 + _t445_x2_t_^3,
    1.7424253005320733 + 3(_t445_x2_t_^2)*_t445_x2ˍt_t_,
    -8.922607990476102 + _t445_x3_t_^3,
    3.8180046062041497 + 3(_t445_x3_t_^2)*_t445_x3ˍt_t_,
    -0.9589570910459244 + _t445_x1_t_^3,
    0.5006362501123839 + 3(_t445_x1_t_^2)*_t445_x1ˍt_t_,
    _t445_x2ˍt_t_ + _t445_x1_t_*_tpb_,
    _t445_x3ˍt_t_ + _t445_x1_t_*_tpc_,
    _t445_x1ˍt_t_ + _t445_x2_t_*_tpa_
]

