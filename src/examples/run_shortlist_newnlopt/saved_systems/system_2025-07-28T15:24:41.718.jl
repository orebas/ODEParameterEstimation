# Polynomial system saved on 2025-07-28T15:24:41.718
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:24:41.718
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t56_x1_t_
_t56_x2_t_
_t56_x2ˍt_t_
_t56_x2ˍtt_t_
_t56_x1ˍt_t_
_t56_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t56_x1_t_ _t56_x2_t_ _t56_x2ˍt_t_ _t56_x2ˍtt_t_ _t56_x1ˍt_t_ _t56_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t56_x1_t__t56_x2_t__t56_x2ˍt_t__t56_x2ˍtt_t__t56_x1ˍt_t__t56_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -3.752368174683724 + _t56_x2_t_,
    -8.537466830199516 + _t56_x2ˍt_t_,
    17.732373187447838 + _t56_x2ˍtt_t_,
    -6.594026128999591 + _t56_x1_t_,
    12.377849295820221 + _t56_x1ˍt_t_,
    27.431689012348315 + _t56_x1ˍtt_t_,
    _t56_x2ˍt_t_ + _t56_x2_t_*_tpc_ - _t56_x1_t_*_t56_x2_t_*_tpd_,
    _t56_x2ˍtt_t_ + _t56_x2ˍt_t_*_tpc_ - _t56_x1_t_*_t56_x2ˍt_t_*_tpd_ - _t56_x1ˍt_t_*_t56_x2_t_*_tpd_,
    _t56_x1ˍt_t_ - _t56_x1_t_*_tpa_ + _t56_x1_t_*_t56_x2_t_*_tpb_,
    _t56_x1ˍtt_t_ - _t56_x1ˍt_t_*_tpa_ + _t56_x1_t_*_t56_x2ˍt_t_*_tpb_ + _t56_x1ˍt_t_*_t56_x2_t_*_tpb_
]

