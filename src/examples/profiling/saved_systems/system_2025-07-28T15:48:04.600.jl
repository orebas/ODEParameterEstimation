# Polynomial system saved on 2025-07-28T15:48:04.600
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:48:04.600
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
    -17.466643363287986 + _t45_x2_t_^3,
    6.8379565595849705 + 3(_t45_x2_t_^2)*_t45_x2ˍt_t_,
    -39.02357630197501 + _t45_x3_t_^3,
    17.52923085245349 + 3(_t45_x3_t_^2)*_t45_x3ˍt_t_,
    -4.8518392124760545 + _t45_x1_t_^3,
    2.230807414616401 + 3(_t45_x1_t_^2)*_t45_x1ˍt_t_,
    _t45_x2ˍt_t_ + _t45_x1_t_*_tpb_,
    _t45_x3ˍt_t_ + _t45_x1_t_*_tpc_,
    _t45_x1ˍt_t_ + _t45_x2_t_*_tpa_
]

