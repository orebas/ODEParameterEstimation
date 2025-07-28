# Polynomial system saved on 2025-07-28T15:25:25.208
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:25:25.208
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t445_x1_t_
_t445_x2_t_
_t445_x2ˍt_t_
_t445_x2ˍtt_t_
_t445_x1ˍt_t_
_t445_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t445_x1_t_ _t445_x2_t_ _t445_x2ˍt_t_ _t445_x2ˍtt_t_ _t445_x1ˍt_t_ _t445_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t445_x1_t__t445_x2_t__t445_x2ˍt_t__t445_x2ˍtt_t__t445_x1ˍt_t__t445_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -0.38551706021092547 + _t445_x2_t_,
    0.3715983224860237 + _t445_x2ˍt_t_,
    -1.2632576953938943 + _t445_x2ˍtt_t_,
    -2.545129198868299 + _t445_x1_t_,
    -2.934622314245702 + _t445_x1ˍt_t_,
    -4.23491168800987 + _t445_x1ˍtt_t_,
    _t445_x2ˍt_t_ + _t445_x2_t_*_tpc_ - _t445_x1_t_*_t445_x2_t_*_tpd_,
    _t445_x2ˍtt_t_ + _t445_x2ˍt_t_*_tpc_ - _t445_x1_t_*_t445_x2ˍt_t_*_tpd_ - _t445_x1ˍt_t_*_t445_x2_t_*_tpd_,
    _t445_x1ˍt_t_ - _t445_x1_t_*_tpa_ + _t445_x1_t_*_t445_x2_t_*_tpb_,
    _t445_x1ˍtt_t_ - _t445_x1ˍt_t_*_tpa_ + _t445_x1_t_*_t445_x2ˍt_t_*_tpb_ + _t445_x1ˍt_t_*_t445_x2_t_*_tpb_
]

