# Polynomial system saved on 2025-07-28T15:49:46.854
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:49:46.841
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t112_x1_t_
_t112_x2_t_
_t112_x2ˍt_t_
_t112_x2ˍtt_t_
_t112_x1ˍt_t_
_t112_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t112_x1_t_ _t112_x2_t_ _t112_x2ˍt_t_ _t112_x2ˍtt_t_ _t112_x1ˍt_t_ _t112_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t112_x1_t__t112_x2_t__t112_x2ˍt_t__t112_x2ˍtt_t__t112_x1ˍt_t__t112_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -4.591122109017879 + _t112_x2_t_,
    -4.456931623282662 + _t112_x2ˍt_t_,
    43.656947820045275 + _t112_x2ˍtt_t_,
    -4.9634483316590705 + _t112_x1_t_,
    13.06391672335457 + _t112_x1ˍt_t_,
    -14.476083445097762 + _t112_x1ˍtt_t_,
    _t112_x2ˍt_t_ + _t112_x2_t_*_tpc_ - _t112_x1_t_*_t112_x2_t_*_tpd_,
    _t112_x2ˍtt_t_ + _t112_x2ˍt_t_*_tpc_ - _t112_x1_t_*_t112_x2ˍt_t_*_tpd_ - _t112_x1ˍt_t_*_t112_x2_t_*_tpd_,
    _t112_x1ˍt_t_ - _t112_x1_t_*_tpa_ + _t112_x1_t_*_t112_x2_t_*_tpb_,
    _t112_x1ˍtt_t_ - _t112_x1ˍt_t_*_tpa_ + _t112_x1_t_*_t112_x2ˍt_t_*_tpb_ + _t112_x1ˍt_t_*_t112_x2_t_*_tpb_
]

