# Polynomial system saved on 2025-07-28T15:12:43.512
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:12:43.512
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t278_x1_t_
_t278_x2_t_
_t278_x3_t_
_t278_x2ˍt_t_
_t278_x3ˍt_t_
_t278_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t278_x1_t_ _t278_x2_t_ _t278_x3_t_ _t278_x2ˍt_t_ _t278_x3ˍt_t_ _t278_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t278_x1_t__t278_x2_t__t278_x3_t__t278_x2ˍt_t__t278_x3ˍt_t__t278_x1ˍt_t_]

# Polynomial System
poly_system = [
    -9.215945302358898 + _t278_x2_t_^3,
    3.436581289647535 + 3(_t278_x2_t_^2)*_t278_x2ˍt_t_,
    -18.50203959189197 + _t278_x3_t_^3,
    8.203597979885238 + 3(_t278_x3_t_^2)*_t278_x3ˍt_t_,
    -2.212310850466464 + _t278_x1_t_^3,
    1.0679036526877237 + 3(_t278_x1_t_^2)*_t278_x1ˍt_t_,
    _t278_x2ˍt_t_ + _t278_x1_t_*_tpb_,
    _t278_x3ˍt_t_ + _t278_x1_t_*_tpc_,
    _t278_x1ˍt_t_ + _t278_x2_t_*_tpa_
]

