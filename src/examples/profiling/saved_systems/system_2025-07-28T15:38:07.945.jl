# Polynomial system saved on 2025-07-28T15:38:07.945
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:38:07.945
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t156_x1_t_
_t156_x2_t_
_t156_x3_t_
_t156_x2ˍt_t_
_t156_x3ˍt_t_
_t156_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t156_x1_t_ _t156_x2_t_ _t156_x3_t_ _t156_x2ˍt_t_ _t156_x3ˍt_t_ _t156_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t156_x1_t__t156_x2_t__t156_x3_t__t156_x2ˍt_t__t156_x3ˍt_t__t156_x1ˍt_t_]

# Polynomial System
poly_system = [
    -6.159701122467743 + _t156_x2_t_^3,
    2.1902291028935372 + 3(_t156_x2_t_^2)*_t156_x2ˍt_t_,
    -11.385348480884698 + _t156_x3_t_^3,
    4.948095751479825 + 3(_t156_x3_t_^2)*_t156_x3ˍt_t_,
    -1.282021282768308 + _t156_x1_t_^3,
    0.6489897107210896 + 3(_t156_x1_t_^2)*_t156_x1ˍt_t_,
    _t156_x2ˍt_t_ + _t156_x1_t_*_tpb_,
    _t156_x3ˍt_t_ + _t156_x1_t_*_tpc_,
    _t156_x1ˍt_t_ + _t156_x2_t_*_tpa_
]

