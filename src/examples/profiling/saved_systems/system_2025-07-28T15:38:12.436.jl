# Polynomial system saved on 2025-07-28T15:38:12.436
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:38:12.436
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t179_x1_t_
_t179_x2_t_
_t179_x3_t_
_t179_x2ˍt_t_
_t179_x3ˍt_t_
_t179_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t179_x1_t_ _t179_x2_t_ _t179_x3_t_ _t179_x2ˍt_t_ _t179_x3ˍt_t_ _t179_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t179_x1_t__t179_x2_t__t179_x3_t__t179_x2ˍt_t__t179_x3ˍt_t__t179_x1ˍt_t_]

# Polynomial System
poly_system = [
    -5.0362554385517875 + _t179_x2_t_^3,
    1.7354019610189402 + 3(_t179_x2_t_^2)*_t179_x2ˍt_t_,
    -8.884515790787994 + _t179_x3_t_^3,
    3.800511249669131 + 3(_t179_x3_t_^2)*_t179_x3ˍt_t_,
    -0.9539623388311829 + _t179_x1_t_^3,
    0.4983233566595314 + 3(_t179_x1_t_^2)*_t179_x1ˍt_t_,
    _t179_x2ˍt_t_ + _t179_x1_t_*_tpb_,
    _t179_x3ˍt_t_ + _t179_x1_t_*_tpc_,
    _t179_x1ˍt_t_ + _t179_x2_t_*_tpa_
]

