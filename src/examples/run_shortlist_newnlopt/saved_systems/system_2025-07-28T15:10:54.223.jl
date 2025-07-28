# Polynomial system saved on 2025-07-28T15:10:54.224
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:10:54.223
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t390_x1_t_
_t390_x2_t_
_t390_x3_t_
_t390_x2ˍt_t_
_t390_x3ˍt_t_
_t390_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t390_x1_t_ _t390_x2_t_ _t390_x3_t_ _t390_x2ˍt_t_ _t390_x3ˍt_t_ _t390_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t390_x1_t__t390_x2_t__t390_x3_t__t390_x2ˍt_t__t390_x3ˍt_t__t390_x1ˍt_t_]

# Polynomial System
poly_system = [
    -6.126947476856146 + _t390_x2_t_^3,
    2.1769385154315155 + 3(_t390_x2_t_^2)*_t390_x2ˍt_t_,
    -11.311381071436681 + _t390_x3_t_^3,
    4.914187519505785 + 3(_t390_x3_t_^2)*_t390_x3ˍt_t_,
    -1.272319609297631 + _t390_x1_t_^3,
    0.6445652423088781 + 3(_t390_x1_t_^2)*_t390_x1ˍt_t_,
    _t390_x2ˍt_t_ + _t390_x1_t_*_tpb_,
    _t390_x3ˍt_t_ + _t390_x1_t_*_tpc_,
    _t390_x1ˍt_t_ + _t390_x2_t_*_tpa_
]

