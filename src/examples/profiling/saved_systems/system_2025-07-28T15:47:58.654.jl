# Polynomial system saved on 2025-07-28T15:47:58.654
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:47:58.654
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
    -17.46664337154783 + _t45_x2_t_^3,
    6.837956466544318 + 3(_t45_x2_t_^2)*_t45_x2ˍt_t_,
    -39.023576581613106 + _t45_x3_t_^3,
    17.529231614021672 + 3(_t45_x3_t_^2)*_t45_x3ˍt_t_,
    -4.851839256232821 + _t45_x1_t_^3,
    2.2308079668105374 + 3(_t45_x1_t_^2)*_t45_x1ˍt_t_,
    _t45_x2ˍt_t_ + _t45_x1_t_*_tpb_,
    _t45_x3ˍt_t_ + _t45_x1_t_*_tpc_,
    _t45_x1ˍt_t_ + _t45_x2_t_*_tpa_
]

