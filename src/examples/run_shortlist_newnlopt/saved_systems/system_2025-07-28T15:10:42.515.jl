# Polynomial system saved on 2025-07-28T15:10:42.516
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:10:42.516
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
    -7.495902063609234 + _t334_x2_t_^3,
    2.7337381810961108 + 3(_t334_x2_t_^2)*_t334_x2ˍt_t_,
    -14.4486192141422 + _t334_x3_t_^3,
    6.351114412240759 + 3(_t334_x3_t_^2)*_t334_x3ˍt_t_,
    -1.6833309295492336 + _t334_x1_t_^3,
    0.8308235835262278 + 3(_t334_x1_t_^2)*_t334_x1ˍt_t_,
    _t334_x2ˍt_t_ + _t334_x1_t_*_tpb_,
    _t334_x3ˍt_t_ + _t334_x1_t_*_tpc_,
    _t334_x1ˍt_t_ + _t334_x2_t_*_tpa_
]

