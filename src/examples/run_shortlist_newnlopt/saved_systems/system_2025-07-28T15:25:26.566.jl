# Polynomial system saved on 2025-07-28T15:25:26.566
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:25:26.566
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
    -4.804236572868378 + _t501_x2_t_,
    0.8910707533254323 + _t501_x2ˍt_t_,
    38.0216475703249 + _t501_x2ˍtt_t_,
    -3.518161612622874 + _t501_x1_t_,
    9.934577841711379 + _t501_x1ˍt_t_,
    -30.884475228350777 + _t501_x1ˍtt_t_,
    _t501_x2ˍt_t_ + _t501_x2_t_*_tpc_ - _t501_x1_t_*_t501_x2_t_*_tpd_,
    _t501_x2ˍtt_t_ + _t501_x2ˍt_t_*_tpc_ - _t501_x1_t_*_t501_x2ˍt_t_*_tpd_ - _t501_x1ˍt_t_*_t501_x2_t_*_tpd_,
    _t501_x1ˍt_t_ - _t501_x1_t_*_tpa_ + _t501_x1_t_*_t501_x2_t_*_tpb_,
    _t501_x1ˍtt_t_ - _t501_x1ˍt_t_*_tpa_ + _t501_x1_t_*_t501_x2ˍt_t_*_tpb_ + _t501_x1ˍt_t_*_t501_x2_t_*_tpb_
]

