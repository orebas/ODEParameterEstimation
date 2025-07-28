# Polynomial system saved on 2025-07-28T15:11:17.950
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:11:17.950
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
    -17.466643801030987 + _t111_x2_t_^3,
    6.837956904697774 + 3(_t111_x2_t_^2)*_t111_x2ˍt_t_,
    -39.023575832487104 + _t111_x3_t_^3,
    17.529225927865212 + 3(_t111_x3_t_^2)*_t111_x3ˍt_t_,
    -4.851839246225308 + _t111_x1_t_^3,
    2.2308067598783845 + 3(_t111_x1_t_^2)*_t111_x1ˍt_t_,
    _t111_x2ˍt_t_ + _t111_x1_t_*_tpb_,
    _t111_x3ˍt_t_ + _t111_x1_t_*_tpc_,
    _t111_x1ˍt_t_ + _t111_x2_t_*_tpa_
]

