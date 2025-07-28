# Polynomial system saved on 2025-07-28T15:11:34.607
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:11:34.597
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
    -14.048679729578337 + _t167_x2_t_^3,
    5.42439337550533 + 3(_t167_x2_t_^2)*_t167_x2ˍt_t_,
    -30.35377218699872 + _t167_x3_t_^3,
    13.598588768295508 + 3(_t167_x3_t_^2)*_t167_x3ˍt_t_,
    -3.7439381193154304 + _t167_x1_t_^3,
    1.7453622954163477 + 3(_t167_x1_t_^2)*_t167_x1ˍt_t_,
    _t167_x2ˍt_t_ + _t167_x1_t_*_tpb_,
    _t167_x3ˍt_t_ + _t167_x1_t_*_tpc_,
    _t167_x1ˍt_t_ + _t167_x2_t_*_tpa_
]

