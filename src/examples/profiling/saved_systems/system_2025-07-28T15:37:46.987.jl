# Polynomial system saved on 2025-07-28T15:37:46.988
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:37:46.987
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
    -17.466643287079922 + _t45_x2_t_^3,
    6.837955751005161 + 3(_t45_x2_t_^2)*_t45_x2ˍt_t_,
    -39.02357671650146 + _t45_x3_t_^3,
    17.52923257248309 + 3(_t45_x3_t_^2)*_t45_x3ˍt_t_,
    -4.851839268148366 + _t45_x1_t_^3,
    2.230807856657821 + 3(_t45_x1_t_^2)*_t45_x1ˍt_t_,
    _t45_x2ˍt_t_ + _t45_x1_t_*_tpb_,
    _t45_x3ˍt_t_ + _t45_x1_t_*_tpc_,
    _t45_x1ˍt_t_ + _t45_x2_t_*_tpa_
]

