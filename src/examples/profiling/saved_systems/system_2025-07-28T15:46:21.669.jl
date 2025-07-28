# Polynomial system saved on 2025-07-28T15:46:21.675
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:46:21.669
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
    -17.466643346980035 + _t45_x2_t_^3,
    6.837956388784577 + 3(_t45_x2_t_^2)*_t45_x2ˍt_t_,
    -39.02357665104603 + _t45_x3_t_^3,
    17.529231420843402 + 3(_t45_x3_t_^2)*_t45_x3ˍt_t_,
    -4.851839330527195 + _t45_x1_t_^3,
    2.2308077157481776 + 3(_t45_x1_t_^2)*_t45_x1ˍt_t_,
    _t45_x2ˍt_t_ + _t45_x1_t_*_tpb_,
    _t45_x3ˍt_t_ + _t45_x1_t_*_tpc_,
    _t45_x1ˍt_t_ + _t45_x2_t_*_tpa_
]

