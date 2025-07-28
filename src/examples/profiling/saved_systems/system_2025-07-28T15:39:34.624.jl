# Polynomial system saved on 2025-07-28T15:39:34.626
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:39:34.624
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
    -4.591122113442484 + _t112_x2_t_,
    -4.456931486752881 + _t112_x2ˍt_t_,
    43.65695699821382 + _t112_x2ˍtt_t_,
    -4.963448302213028 + _t112_x1_t_,
    13.063916637306738 + _t112_x1ˍt_t_,
    -14.476091600172449 + _t112_x1ˍtt_t_,
    _t112_x2ˍt_t_ + _t112_x2_t_*_tpc_ - _t112_x1_t_*_t112_x2_t_*_tpd_,
    _t112_x2ˍtt_t_ + _t112_x2ˍt_t_*_tpc_ - _t112_x1_t_*_t112_x2ˍt_t_*_tpd_ - _t112_x1ˍt_t_*_t112_x2_t_*_tpd_,
    _t112_x1ˍt_t_ - _t112_x1_t_*_tpa_ + _t112_x1_t_*_t112_x2_t_*_tpb_,
    _t112_x1ˍtt_t_ - _t112_x1ˍt_t_*_tpa_ + _t112_x1_t_*_t112_x2ˍt_t_*_tpb_ + _t112_x1ˍt_t_*_t112_x2_t_*_tpb_
]

