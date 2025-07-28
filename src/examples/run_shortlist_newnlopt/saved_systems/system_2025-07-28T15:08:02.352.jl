# Polynomial system saved on 2025-07-28T15:08:02.352
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:08:02.352
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpbeta_
_t390_x1_t_
_t390_x2_t_
_t390_x3_t_
_t390_x2ˍt_t_
_t390_x3ˍt_t_
_t390_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpbeta_ _t390_x1_t_ _t390_x2_t_ _t390_x3_t_ _t390_x2ˍt_t_ _t390_x3ˍt_t_ _t390_x1ˍt_t_
varlist = [_tpa__tpb__tpbeta__t390_x1_t__t390_x2_t__t390_x3_t__t390_x2ˍt_t__t390_x3ˍt_t__t390_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.036065110701795 + _t390_x2_t_,
    -0.11917872479396863 + _t390_x2ˍt_t_,
    -4.0018676358722995 + _t390_x3_t_,
    -0.000480224116316208 + _t390_x3ˍt_t_,
    -0.595893623969794 + _t390_x1_t_,
    0.4036065110701843 + _t390_x1ˍt_t_,
    _t390_x2ˍt_t_ - _t390_x1_t_*_tpb_,
    _t390_x3ˍt_t_ - _t390_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t390_x1ˍt_t_ + _t390_x2_t_*_tpa_
]

