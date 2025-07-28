# Polynomial system saved on 2025-07-28T15:09:39
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:09:39
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t111_x1_t_
_t111_x2_t_
_t111_x3_t_
_t111_x2ˍt_t_
_t111_x3ˍt_t_
_t111_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t111_x1_t_ _t111_x2_t_ _t111_x3_t_ _t111_x2ˍt_t_ _t111_x3ˍt_t_ _t111_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t111_x1_t__t111_x2_t__t111_x3_t__t111_x2ˍt_t__t111_x3ˍt_t__t111_x1ˍt_t_]

# Polynomial System
poly_system = [
    -17.466643230353302 + _t111_x2_t_^3,
    6.837956017031102 + 3(_t111_x2_t_^2)*_t111_x2ˍt_t_,
    -39.02357636285237 + _t111_x3_t_^3,
    17.529226188352048 + 3(_t111_x3_t_^2)*_t111_x3ˍt_t_,
    -4.851839184703346 + _t111_x1_t_^3,
    2.23080719893069 + 3(_t111_x1_t_^2)*_t111_x1ˍt_t_,
    _t111_x2ˍt_t_ + _t111_x1_t_*_tpb_,
    _t111_x3ˍt_t_ + _t111_x1_t_*_tpc_,
    _t111_x1ˍt_t_ + _t111_x2_t_*_tpa_
]

