# Polynomial system saved on 2025-07-28T15:39:35.650
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:39:35.649
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t156_x1_t_
_t156_x2_t_
_t156_x2ˍt_t_
_t156_x2ˍtt_t_
_t156_x1ˍt_t_
_t156_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t156_x1_t_ _t156_x2_t_ _t156_x2ˍt_t_ _t156_x2ˍtt_t_ _t156_x1ˍt_t_ _t156_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t156_x1_t__t156_x2_t__t156_x2ˍt_t__t156_x2ˍtt_t__t156_x1ˍt_t__t156_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -4.68685000491185 + _t156_x2_t_,
    -3.371104708363496 + _t156_x2ˍt_t_,
    44.95959034861275 + _t156_x2ˍtt_t_,
    -4.649081221133787 + _t156_x1_t_,
    12.636992518959362 + _t156_x1ˍt_t_,
    -20.24667465240034 + _t156_x1ˍtt_t_,
    _t156_x2ˍt_t_ + _t156_x2_t_*_tpc_ - _t156_x1_t_*_t156_x2_t_*_tpd_,
    _t156_x2ˍtt_t_ + _t156_x2ˍt_t_*_tpc_ - _t156_x1_t_*_t156_x2ˍt_t_*_tpd_ - _t156_x1ˍt_t_*_t156_x2_t_*_tpd_,
    _t156_x1ˍt_t_ - _t156_x1_t_*_tpa_ + _t156_x1_t_*_t156_x2_t_*_tpb_,
    _t156_x1ˍtt_t_ - _t156_x1ˍt_t_*_tpa_ + _t156_x1_t_*_t156_x2ˍt_t_*_tpb_ + _t156_x1ˍt_t_*_t156_x2_t_*_tpb_
]

