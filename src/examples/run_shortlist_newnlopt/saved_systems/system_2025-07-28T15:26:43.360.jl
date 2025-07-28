# Polynomial system saved on 2025-07-28T15:26:43.360
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:26:43.360
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t278_x1_t_
_t278_x2_t_
_t278_x2ˍt_t_
_t278_x1ˍt_t_
_t445_x1_t_
_t445_x2_t_
_t445_x2ˍt_t_
_t445_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t278_x1_t_ _t278_x2_t_ _t278_x2ˍt_t_ _t278_x1ˍt_t_ _t445_x1_t_ _t445_x2_t_ _t445_x2ˍt_t_ _t445_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t278_x1_t__t278_x2_t__t278_x2ˍt_t__t278_x1ˍt_t__t445_x1_t__t445_x2_t__t445_x2ˍt_t__t445_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.519408005635672 + _t278_x2_t_,
    -5.101088890224761 + _t278_x2ˍt_t_,
    -5.160883817325007 + _t278_x1_t_,
    13.250407946421742 + _t278_x1ˍt_t_,
    _t278_x2ˍt_t_ + _t278_x2_t_*_tpc_ - _t278_x1_t_*_t278_x2_t_*_tpd_,
    _t278_x1ˍt_t_ - _t278_x1_t_*_tpa_ + _t278_x1_t_*_t278_x2_t_*_tpb_,
    -0.3855170409684021 + _t445_x2_t_,
    0.3715986620567104 + _t445_x2ˍt_t_,
    -2.545129281487294 + _t445_x1_t_,
    -2.9346226470610426 + _t445_x1ˍt_t_,
    _t445_x2ˍt_t_ + _t445_x2_t_*_tpc_ - _t445_x1_t_*_t445_x2_t_*_tpd_,
    _t445_x1ˍt_t_ - _t445_x1_t_*_tpa_ + _t445_x1_t_*_t445_x2_t_*_tpb_
]

