# Polynomial system saved on 2025-07-28T15:26:48.470
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:26:48.470
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t390_x1_t_
_t390_x2_t_
_t390_x2ˍt_t_
_t390_x1ˍt_t_
_t501_x1_t_
_t501_x2_t_
_t501_x2ˍt_t_
_t501_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t390_x1_t_ _t390_x2_t_ _t390_x2ˍt_t_ _t390_x1ˍt_t_ _t501_x1_t_ _t501_x2_t_ _t501_x2ˍt_t_ _t501_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t390_x1_t__t390_x2_t__t390_x2ˍt_t__t390_x1ˍt_t__t501_x1_t__t501_x2_t__t501_x2ˍt_t__t501_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.793032385785027 + _t390_x2_t_,
    -1.3563469964551593 + _t390_x2ˍt_t_,
    -4.1037290774935204 + _t390_x1_t_,
    11.546769059212789 + _t390_x1ˍt_t_,
    _t390_x2ˍt_t_ + _t390_x2_t_*_tpc_ - _t390_x1_t_*_t390_x2_t_*_tpd_,
    _t390_x1ˍt_t_ - _t390_x1_t_*_tpa_ + _t390_x1_t_*_t390_x2_t_*_tpb_,
    -4.804236595152716 + _t501_x2_t_,
    0.8910678280600802 + _t501_x2ˍt_t_,
    -3.518161570803926 + _t501_x1_t_,
    9.934564114022328 + _t501_x1ˍt_t_,
    _t501_x2ˍt_t_ + _t501_x2_t_*_tpc_ - _t501_x1_t_*_t501_x2_t_*_tpd_,
    _t501_x1ˍt_t_ - _t501_x1_t_*_tpa_ + _t501_x1_t_*_t501_x2_t_*_tpb_
]

