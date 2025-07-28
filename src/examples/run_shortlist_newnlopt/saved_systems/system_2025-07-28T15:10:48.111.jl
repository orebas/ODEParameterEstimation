# Polynomial system saved on 2025-07-28T15:10:48.112
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:10:48.111
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
    -6.1269474974021 + _t390_x2_t_^3,
    2.1769377645220365 + 3(_t390_x2_t_^2)*_t390_x2ˍt_t_,
    -11.311380653938166 + _t390_x3_t_^3,
    4.914186943109382 + 3(_t390_x3_t_^2)*_t390_x3ˍt_t_,
    -1.272319710226198 + _t390_x1_t_^3,
    0.6445652355501227 + 3(_t390_x1_t_^2)*_t390_x1ˍt_t_,
    _t390_x2ˍt_t_ + _t390_x1_t_*_tpb_,
    _t390_x3ˍt_t_ + _t390_x1_t_*_tpc_,
    _t390_x1ˍt_t_ + _t390_x2_t_*_tpa_
]

