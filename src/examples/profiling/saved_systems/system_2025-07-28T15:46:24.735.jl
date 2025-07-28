# Polynomial system saved on 2025-07-28T15:46:24.735
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:46:24.735
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t45_x1_t_
_t45_x2_t_
_t45_x3_t_
_t45_x2ˍt_t_
_t45_x3ˍt_t_
_t45_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t45_x1_t_ _t45_x2_t_ _t45_x3_t_ _t45_x2ˍt_t_ _t45_x3ˍt_t_ _t45_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t45_x1_t__t45_x2_t__t45_x3_t__t45_x2ˍt_t__t45_x3ˍt_t__t45_x1ˍt_t_]

# Polynomial System
poly_system = [
    -17.46664333874595 + _t45_x2_t_^3,
    6.837956097185548 + 3(_t45_x2_t_^2)*_t45_x2ˍt_t_,
    -39.02357770302026 + _t45_x3_t_^3,
    17.52923101219706 + 3(_t45_x3_t_^2)*_t45_x3ˍt_t_,
    -4.851839838488234 + _t45_x1_t_^3,
    2.2308071833433822 + 3(_t45_x1_t_^2)*_t45_x1ˍt_t_,
    _t45_x2ˍt_t_ + _t45_x1_t_*_tpb_,
    _t45_x3ˍt_t_ + _t45_x1_t_*_tpc_,
    _t45_x1ˍt_t_ + _t45_x2_t_*_tpa_
]

