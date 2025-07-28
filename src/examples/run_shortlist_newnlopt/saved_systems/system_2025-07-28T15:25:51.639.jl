# Polynomial system saved on 2025-07-28T15:25:51.639
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:25:51.639
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
    -3.7523681779775186 + _t56_x2_t_,
    -8.537466684803533 + _t56_x2ˍt_t_,
    17.73238734808183 + _t56_x2ˍtt_t_,
    -6.5940261855532984 + _t56_x1_t_,
    12.377853342745055 + _t56_x1ˍt_t_,
    27.431794308684402 + _t56_x1ˍtt_t_,
    _t56_x2ˍt_t_ + _t56_x2_t_*_tpc_ - _t56_x1_t_*_t56_x2_t_*_tpd_,
    _t56_x2ˍtt_t_ + _t56_x2ˍt_t_*_tpc_ - _t56_x1_t_*_t56_x2ˍt_t_*_tpd_ - _t56_x1ˍt_t_*_t56_x2_t_*_tpd_,
    _t56_x1ˍt_t_ - _t56_x1_t_*_tpa_ + _t56_x1_t_*_t56_x2_t_*_tpb_,
    _t56_x1ˍtt_t_ - _t56_x1ˍt_t_*_tpa_ + _t56_x1_t_*_t56_x2ˍt_t_*_tpb_ + _t56_x1ˍt_t_*_t56_x2_t_*_tpb_
]

