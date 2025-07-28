# Polynomial system saved on 2025-07-28T15:49:39.589
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:49:39.589
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t45_x1_t_
_t45_x2_t_
_t45_x2ˍt_t_
_t45_x2ˍtt_t_
_t45_x1ˍt_t_
_t45_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t45_x1_t_ _t45_x2_t_ _t45_x2ˍt_t_ _t45_x2ˍtt_t_ _t45_x1ˍt_t_ _t45_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t45_x1_t__t45_x2_t__t45_x2ˍt_t__t45_x2ˍtt_t__t45_x1ˍt_t__t45_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -0.4834264160438895 + _t45_x2_t_,
    0.6565351514791463 + _t45_x2ˍt_t_,
    -1.736907671672865 + _t45_x2ˍtt_t_,
    -2.0523687743899455 + _t45_x1_t_,
    -2.1855914403791585 + _t45_x1ˍt_t_,
    -3.540163547876731 + _t45_x1ˍtt_t_,
    _t45_x2ˍt_t_ + _t45_x2_t_*_tpc_ - _t45_x1_t_*_t45_x2_t_*_tpd_,
    _t45_x2ˍtt_t_ + _t45_x2ˍt_t_*_tpc_ - _t45_x1_t_*_t45_x2ˍt_t_*_tpd_ - _t45_x1ˍt_t_*_t45_x2_t_*_tpd_,
    _t45_x1ˍt_t_ - _t45_x1_t_*_tpa_ + _t45_x1_t_*_t45_x2_t_*_tpb_,
    _t45_x1ˍtt_t_ - _t45_x1ˍt_t_*_tpa_ + _t45_x1_t_*_t45_x2ˍt_t_*_tpb_ + _t45_x1ˍt_t_*_t45_x2_t_*_tpb_
]

