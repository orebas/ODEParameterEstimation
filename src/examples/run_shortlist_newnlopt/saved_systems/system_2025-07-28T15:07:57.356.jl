# Polynomial system saved on 2025-07-28T15:07:57.356
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:07:57.356
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
    -4.036065116602239 + _t390_x2_t_,
    -0.11917870434178127 + _t390_x2ˍt_t_,
    -4.001867635867614 + _t390_x3_t_,
    -0.0004802241304328112 + _t390_x3ˍt_t_,
    -0.5958936239363668 + _t390_x1_t_,
    0.403606529213192 + _t390_x1ˍt_t_,
    _t390_x2ˍt_t_ - _t390_x1_t_*_tpb_,
    _t390_x3ˍt_t_ - _t390_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t390_x1ˍt_t_ + _t390_x2_t_*_tpa_
]

