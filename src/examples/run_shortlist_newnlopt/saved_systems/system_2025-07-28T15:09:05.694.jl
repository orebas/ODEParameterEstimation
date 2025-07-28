# Polynomial system saved on 2025-07-28T15:09:05.694
using Symbolics
using StaticArrays

# Metadata
# num_variables: 22
# timestamp: 2025-07-28T15:09:05.694
# num_equations: 22

# Variables
varlist_str = """
_tpa_
_tpb_
_t334_x1_t_
_t334_x2_t_
_t334_x3_t_
_t334_x3ˍt_t_
_t334_x3ˍtt_t_
_t334_x3ˍttt_t_
_t334_x1ˍt_t_
_t334_x2ˍt_t_
_t334_x1ˍtt_t_
_t334_x2ˍtt_t_
_t501_x1_t_
_t501_x2_t_
_t501_x3_t_
_t501_x3ˍt_t_
_t501_x3ˍtt_t_
_t501_x3ˍttt_t_
_t501_x1ˍt_t_
_t501_x2ˍt_t_
_t501_x1ˍtt_t_
_t501_x2ˍtt_t_
"""
@variables _tpa_ _tpb_ _t334_x1_t_ _t334_x2_t_ _t334_x3_t_ _t334_x3ˍt_t_ _t334_x3ˍtt_t_ _t334_x3ˍttt_t_ _t334_x1ˍt_t_ _t334_x2ˍt_t_ _t334_x1ˍtt_t_ _t334_x2ˍtt_t_ _t501_x1_t_ _t501_x2_t_ _t501_x3_t_ _t501_x3ˍt_t_ _t501_x3ˍtt_t_ _t501_x3ˍttt_t_ _t501_x1ˍt_t_ _t501_x2ˍt_t_ _t501_x1ˍtt_t_ _t501_x2ˍtt_t_
varlist = [_tpa__tpb__t334_x1_t__t334_x2_t__t334_x3_t__t334_x3ˍt_t__t334_x3ˍtt_t__t334_x3ˍttt_t__t334_x1ˍt_t__t334_x2ˍt_t__t334_x1ˍtt_t__t334_x2ˍtt_t__t501_x1_t__t501_x2_t__t501_x3_t__t501_x3ˍt_t__t501_x3ˍtt_t__t501_x3ˍttt_t__t501_x1ˍt_t__t501_x2ˍt_t__t501_x1ˍtt_t__t501_x2ˍtt_t_]

# Polynomial System
poly_system = [
    -9.958340704491993 + _t334_x3_t_,
    -2.18185442725365 + _t334_x3ˍt_t_,
    -0.3073523076666026 + _t334_x3ˍtt_t_,
    -0.07437562551355535 + _t334_x3ˍttt_t_,
    -0.9588176373542187(_t334_x1_t_ + _t334_x2_t_) + _t334_x3ˍt_t_,
    -0.9588176373542187(_t334_x1ˍt_t_ + _t334_x2ˍt_t_) + _t334_x3ˍtt_t_,
    -0.9588176373542187(_t334_x1ˍtt_t_ + _t334_x2ˍtt_t_) + _t334_x3ˍttt_t_,
    _t334_x1ˍt_t_ + _t334_x1_t_*_tpa_,
    _t334_x2ˍt_t_ - _t334_x2_t_*_tpb_,
    _t334_x1ˍtt_t_ + _t334_x1ˍt_t_*_tpa_,
    _t334_x2ˍtt_t_ - _t334_x2ˍt_t_*_tpb_,
    -14.093083890279829 + _t501_x3_t_,
    -2.8103640208392893 + _t501_x3ˍt_t_,
    -0.45279304751276006 + _t501_x3ˍtt_t_,
    -0.10055735613615849 + _t501_x3ˍttt_t_,
    -0.9588176373542187(_t501_x1_t_ + _t501_x2_t_) + _t501_x3ˍt_t_,
    -0.9588176373542187(_t501_x1ˍt_t_ + _t501_x2ˍt_t_) + _t501_x3ˍtt_t_,
    -0.9588176373542187(_t501_x1ˍtt_t_ + _t501_x2ˍtt_t_) + _t501_x3ˍttt_t_,
    _t501_x1ˍt_t_ + _t501_x1_t_*_tpa_,
    _t501_x2ˍt_t_ - _t501_x2_t_*_tpb_,
    _t501_x1ˍtt_t_ + _t501_x1ˍt_t_*_tpa_,
    _t501_x2ˍtt_t_ - _t501_x2ˍt_t_*_tpb_
]

