# Polynomial system saved on 2025-07-28T15:11:09.957
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:11:09.957
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
    -9.215945151927734 + _t278_x2_t_^3,
    3.4365807598728697 + 3(_t278_x2_t_^2)*_t278_x2ˍt_t_,
    -18.502039741263843 + _t278_x3_t_^3,
    8.203596643749155 + 3(_t278_x3_t_^2)*_t278_x3ˍt_t_,
    -2.212310848372136 + _t278_x1_t_^3,
    1.0679034293680445 + 3(_t278_x1_t_^2)*_t278_x1ˍt_t_,
    _t278_x2ˍt_t_ + _t278_x1_t_*_tpb_,
    _t278_x3ˍt_t_ + _t278_x1_t_*_tpc_,
    _t278_x1ˍt_t_ + _t278_x2_t_*_tpa_
]

