# Polynomial system saved on 2025-07-28T15:10:16.287
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:10:16.287
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t334_x1_t_
_t334_x2_t_
_t334_x3_t_
_t334_x2ˍt_t_
_t334_x3ˍt_t_
_t334_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t334_x1_t_ _t334_x2_t_ _t334_x3_t_ _t334_x2ˍt_t_ _t334_x3ˍt_t_ _t334_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t334_x1_t__t334_x2_t__t334_x3_t__t334_x2ˍt_t__t334_x3ˍt_t__t334_x1ˍt_t_]

# Polynomial System
poly_system = [
    -7.495902110148376 + _t334_x2_t_^3,
    2.7337382591434682 + 3(_t334_x2_t_^2)*_t334_x2ˍt_t_,
    -14.44862059358948 + _t334_x3_t_^3,
    6.351114025898138 + 3(_t334_x3_t_^2)*_t334_x3ˍt_t_,
    -1.6833309424271787 + _t334_x1_t_^3,
    0.8308235642282026 + 3(_t334_x1_t_^2)*_t334_x1ˍt_t_,
    _t334_x2ˍt_t_ + _t334_x1_t_*_tpb_,
    _t334_x3ˍt_t_ + _t334_x1_t_*_tpc_,
    _t334_x1ˍt_t_ + _t334_x2_t_*_tpa_
]

