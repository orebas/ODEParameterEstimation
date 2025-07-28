# Polynomial system saved on 2025-07-28T15:49:49.207
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:49:49.207
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
    -4.686849989425729 + _t156_x2_t_,
    -3.3711050825590276 + _t156_x2ˍt_t_,
    44.95958756033811 + _t156_x2ˍtt_t_,
    -4.649081133967985 + _t156_x1_t_,
    12.636991426025876 + _t156_x1ˍt_t_,
    -20.246697913312055 + _t156_x1ˍtt_t_,
    _t156_x2ˍt_t_ + _t156_x2_t_*_tpc_ - _t156_x1_t_*_t156_x2_t_*_tpd_,
    _t156_x2ˍtt_t_ + _t156_x2ˍt_t_*_tpc_ - _t156_x1_t_*_t156_x2ˍt_t_*_tpd_ - _t156_x1ˍt_t_*_t156_x2_t_*_tpd_,
    _t156_x1ˍt_t_ - _t156_x1_t_*_tpa_ + _t156_x1_t_*_t156_x2_t_*_tpb_,
    _t156_x1ˍtt_t_ - _t156_x1ˍt_t_*_tpa_ + _t156_x1_t_*_t156_x2ˍt_t_*_tpb_ + _t156_x1ˍt_t_*_t156_x2_t_*_tpb_
]

