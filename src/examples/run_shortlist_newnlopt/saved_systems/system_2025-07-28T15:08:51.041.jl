# Polynomial system saved on 2025-07-28T15:08:51.041
using Symbolics
using StaticArrays

# Metadata
# num_variables: 15
# timestamp: 2025-07-28T15:08:51.041
# num_equations: 15

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
_t334_x3ˍtttt_t_
_t334_x1ˍt_t_
_t334_x2ˍt_t_
_t334_x1ˍtt_t_
_t334_x2ˍtt_t_
_t334_x2ˍttt_t_
_t334_x1ˍttt_t_
"""
@variables _tpa_ _tpb_ _t334_x1_t_ _t334_x2_t_ _t334_x3_t_ _t334_x3ˍt_t_ _t334_x3ˍtt_t_ _t334_x3ˍttt_t_ _t334_x3ˍtttt_t_ _t334_x1ˍt_t_ _t334_x2ˍt_t_ _t334_x1ˍtt_t_ _t334_x2ˍtt_t_ _t334_x2ˍttt_t_ _t334_x1ˍttt_t_
varlist = [_tpa__tpb__t334_x1_t__t334_x2_t__t334_x3_t__t334_x3ˍt_t__t334_x3ˍtt_t__t334_x3ˍttt_t__t334_x3ˍtttt_t__t334_x1ˍt_t__t334_x2ˍt_t__t334_x1ˍtt_t__t334_x2ˍtt_t__t334_x2ˍttt_t__t334_x1ˍttt_t_]

# Polynomial System
poly_system = [
    -9.958340761689785 + _t334_x3_t_,
    -2.1818543039751335 + _t334_x3ˍt_t_,
    -0.30735192848411597 + _t334_x3ˍtt_t_,
    -0.07437746846001377 + _t334_x3ˍttt_t_,
    -0.01360025302127823 + _t334_x3ˍtttt_t_,
    -0.7532708758546366(_t334_x1_t_ + _t334_x2_t_) + _t334_x3ˍt_t_,
    -0.7532708758546366(_t334_x1ˍt_t_ + _t334_x2ˍt_t_) + _t334_x3ˍtt_t_,
    -0.7532708758546366(_t334_x1ˍtt_t_ + _t334_x2ˍtt_t_) + _t334_x3ˍttt_t_,
    -0.7532708758546366(_t334_x1ˍttt_t_ + _t334_x2ˍttt_t_) + _t334_x3ˍtttt_t_,
    _t334_x1ˍt_t_ + _t334_x1_t_*_tpa_,
    _t334_x2ˍt_t_ - _t334_x2_t_*_tpb_,
    _t334_x1ˍtt_t_ + _t334_x1ˍt_t_*_tpa_,
    _t334_x2ˍtt_t_ - _t334_x2ˍt_t_*_tpb_,
    _t334_x2ˍttt_t_ - _t334_x2ˍtt_t_*_tpb_,
    _t334_x1ˍttt_t_ + _t334_x1ˍtt_t_*_tpa_
]

