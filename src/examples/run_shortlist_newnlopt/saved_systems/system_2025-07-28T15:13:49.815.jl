# Polynomial system saved on 2025-07-28T15:13:49.815
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:13:49.815
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
    -6.126947339843404 + _t390_x2_t_^3,
    2.1769385725143953 + 3(_t390_x2_t_^2)*_t390_x2ˍt_t_,
    -11.311380611160278 + _t390_x3_t_^3,
    4.914186871059831 + 3(_t390_x3_t_^2)*_t390_x3ˍt_t_,
    -1.2723196310592915 + _t390_x1_t_^3,
    0.6445653020705044 + 3(_t390_x1_t_^2)*_t390_x1ˍt_t_,
    _t390_x2ˍt_t_ + _t390_x1_t_*_tpb_,
    _t390_x3ˍt_t_ + _t390_x1_t_*_tpc_,
    _t390_x1ˍt_t_ + _t390_x2_t_*_tpa_
]

