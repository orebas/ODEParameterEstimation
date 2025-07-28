# Polynomial system saved on 2025-07-28T15:26:15.172
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:26:15.164
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t334_x1_t_
_t334_x2_t_
_t334_x2ˍt_t_
_t334_x2ˍtt_t_
_t334_x1ˍt_t_
_t334_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t334_x1_t_ _t334_x2_t_ _t334_x2ˍt_t_ _t334_x2ˍtt_t_ _t334_x1ˍt_t_ _t334_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t334_x1_t__t334_x2_t__t334_x2ˍt_t__t334_x2ˍtt_t__t334_x1ˍt_t__t334_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -0.4076668061564258 + _t334_x2_t_,
    0.44304067398491664 + _t334_x2ˍt_t_,
    -1.365256274595822 + _t334_x2ˍtt_t_,
    -2.3915356018254585 + _t334_x1_t_,
    -2.70984869019302 + _t334_x1ˍt_t_,
    -4.0241220010645975 + _t334_x1ˍtt_t_,
    _t334_x2ˍt_t_ + _t334_x2_t_*_tpc_ - _t334_x1_t_*_t334_x2_t_*_tpd_,
    _t334_x2ˍtt_t_ + _t334_x2ˍt_t_*_tpc_ - _t334_x1_t_*_t334_x2ˍt_t_*_tpd_ - _t334_x1ˍt_t_*_t334_x2_t_*_tpd_,
    _t334_x1ˍt_t_ - _t334_x1_t_*_tpa_ + _t334_x1_t_*_t334_x2_t_*_tpb_,
    _t334_x1ˍtt_t_ - _t334_x1ˍt_t_*_tpa_ + _t334_x1_t_*_t334_x2ˍt_t_*_tpb_ + _t334_x1ˍt_t_*_t334_x2_t_*_tpb_
]

