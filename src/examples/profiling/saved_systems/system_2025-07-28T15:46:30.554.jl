# Polynomial system saved on 2025-07-28T15:46:30.554
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:46:30.554
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t67_x1_t_
_t67_x2_t_
_t67_x3_t_
_t67_x2ˍt_t_
_t67_x3ˍt_t_
_t67_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t67_x1_t_ _t67_x2_t_ _t67_x3_t_ _t67_x2ˍt_t_ _t67_x3ˍt_t_ _t67_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t67_x1_t__t67_x2_t__t67_x3_t__t67_x2ˍt_t__t67_x3ˍt_t__t67_x1ˍt_t_]

# Polynomial System
poly_system = [
    -14.103035750789111 + _t67_x2_t_^3,
    5.446833331865938 + 3(_t67_x2_t_^2)*_t67_x2ˍt_t_,
    -30.49006707044909 + _t67_x3_t_^3,
    13.660469376217916 + 3(_t67_x3_t_^2)*_t67_x3ˍt_t_,
    -3.7614302288354713 + _t67_x1_t_^3,
    1.75304904465633 + 3(_t67_x1_t_^2)*_t67_x1ˍt_t_,
    _t67_x2ˍt_t_ + _t67_x1_t_*_tpb_,
    _t67_x3ˍt_t_ + _t67_x1_t_*_tpc_,
    _t67_x1ˍt_t_ + _t67_x2_t_*_tpa_
]

