# Polynomial system saved on 2025-07-28T15:26:25.767
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:26:25.767
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t501_x1_t_
_t501_x2_t_
_t501_x2ˍt_t_
_t501_x2ˍtt_t_
_t501_x1ˍt_t_
_t501_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t501_x1_t_ _t501_x2_t_ _t501_x2ˍt_t_ _t501_x2ˍtt_t_ _t501_x1ˍt_t_ _t501_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t501_x1_t__t501_x2_t__t501_x2ˍt_t__t501_x2ˍtt_t__t501_x1ˍt_t__t501_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -4.804236567629245 + _t501_x2_t_,
    0.8910452166448408 + _t501_x2ˍt_t_,
    38.01738849225876 + _t501_x2ˍtt_t_,
    -3.518161600313519 + _t501_x1_t_,
    9.934630147173579 + _t501_x1ˍt_t_,
    -30.87489431623544 + _t501_x1ˍtt_t_,
    _t501_x2ˍt_t_ + _t501_x2_t_*_tpc_ - _t501_x1_t_*_t501_x2_t_*_tpd_,
    _t501_x2ˍtt_t_ + _t501_x2ˍt_t_*_tpc_ - _t501_x1_t_*_t501_x2ˍt_t_*_tpd_ - _t501_x1ˍt_t_*_t501_x2_t_*_tpd_,
    _t501_x1ˍt_t_ - _t501_x1_t_*_tpa_ + _t501_x1_t_*_t501_x2_t_*_tpb_,
    _t501_x1ˍtt_t_ - _t501_x1ˍt_t_*_tpa_ + _t501_x1_t_*_t501_x2ˍt_t_*_tpb_ + _t501_x1ˍt_t_*_t501_x2_t_*_tpb_
]

