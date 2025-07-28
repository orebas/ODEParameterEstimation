# Polynomial system saved on 2025-07-28T15:18:15.662
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:18:15.661
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t334_x1_t_
_t334_x2_t_
_t334_x1ˍt_t_
_t334_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t334_x1_t_ _t334_x2_t_ _t334_x1ˍt_t_ _t334_x2ˍt_t_
varlist = [_tpa__tpb__t334_x1_t__t334_x2_t__t334_x1ˍt_t__t334_x2ˍt_t_]

# Polynomial System
poly_system = [
    5.1426080188362695 + 3.0_t334_x1_t_ - 0.25_t334_x2_t_,
    0.5451114424338321 + 3.0_t334_x1ˍt_t_ - 0.25_t334_x2ˍt_t_,
    2.941856317384956 + 2.0_t334_x1_t_ + 0.5_t334_x2_t_,
    1.2452124519599352 + 2.0_t334_x1ˍt_t_ + 0.5_t334_x2ˍt_t_,
    _t334_x1ˍt_t_ + _t334_x2_t_*_tpa_,
    _t334_x2ˍt_t_ - _t334_x1_t_*_tpb_
]

