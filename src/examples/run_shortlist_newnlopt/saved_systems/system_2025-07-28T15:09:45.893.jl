# Polynomial system saved on 2025-07-28T15:09:45.893
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:09:45.893
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t167_x1_t_
_t167_x2_t_
_t167_x3_t_
_t167_x2ˍt_t_
_t167_x3ˍt_t_
_t167_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t167_x1_t_ _t167_x2_t_ _t167_x3_t_ _t167_x2ˍt_t_ _t167_x3ˍt_t_ _t167_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t167_x1_t__t167_x2_t__t167_x3_t__t167_x2ˍt_t__t167_x3ˍt_t__t167_x1ˍt_t_]

# Polynomial System
poly_system = [
    -14.048679553929336 + _t167_x2_t_^3,
    5.424393506870329 + 3(_t167_x2_t_^2)*_t167_x2ˍt_t_,
    -30.353772614541626 + _t167_x3_t_^3,
    13.598588871751273 + 3(_t167_x3_t_^2)*_t167_x3ˍt_t_,
    -3.7439381851141795 + _t167_x1_t_^3,
    1.7453623057323429 + 3(_t167_x1_t_^2)*_t167_x1ˍt_t_,
    _t167_x2ˍt_t_ + _t167_x1_t_*_tpb_,
    _t167_x3ˍt_t_ + _t167_x1_t_*_tpc_,
    _t167_x1ˍt_t_ + _t167_x2_t_*_tpa_
]

