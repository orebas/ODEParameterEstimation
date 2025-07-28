# Polynomial system saved on 2025-07-28T15:13:09.690
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:13:09.680
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
    -7.495902182661746 + _t334_x2_t_^3,
    2.7337391888785487 + 3(_t334_x2_t_^2)*_t334_x2ˍt_t_,
    -14.44862008275445 + _t334_x3_t_^3,
    6.351113858013448 + 3(_t334_x3_t_^2)*_t334_x3ˍt_t_,
    -1.6833309013491096 + _t334_x1_t_^3,
    0.8308235622717207 + 3(_t334_x1_t_^2)*_t334_x1ˍt_t_,
    _t334_x2ˍt_t_ + _t334_x1_t_*_tpb_,
    _t334_x3ˍt_t_ + _t334_x1_t_*_tpc_,
    _t334_x1ˍt_t_ + _t334_x2_t_*_tpa_
]

