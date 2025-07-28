# Polynomial system saved on 2025-07-28T15:25:10.027
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:25:10.027
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t167_x1_t_
_t167_x2_t_
_t167_x2ˍt_t_
_t167_x2ˍtt_t_
_t167_x1ˍt_t_
_t167_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t167_x1_t_ _t167_x2_t_ _t167_x2ˍt_t_ _t167_x2ˍtt_t_ _t167_x1ˍt_t_ _t167_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t167_x1_t__t167_x2_t__t167_x2ˍt_t__t167_x2ˍtt_t__t167_x1ˍt_t__t167_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -4.1832668928590255 + _t167_x2_t_,
    -7.158825100033318 + _t167_x2ˍt_t_,
    32.38795873021704 + _t167_x2ˍtt_t_,
    -5.889125220521482 + _t167_x1_t_,
    13.338516471048827 + _t167_x1ˍt_t_,
    7.732371516198552 + _t167_x1ˍtt_t_,
    _t167_x2ˍt_t_ + _t167_x2_t_*_tpc_ - _t167_x1_t_*_t167_x2_t_*_tpd_,
    _t167_x2ˍtt_t_ + _t167_x2ˍt_t_*_tpc_ - _t167_x1_t_*_t167_x2ˍt_t_*_tpd_ - _t167_x1ˍt_t_*_t167_x2_t_*_tpd_,
    _t167_x1ˍt_t_ - _t167_x1_t_*_tpa_ + _t167_x1_t_*_t167_x2_t_*_tpb_,
    _t167_x1ˍtt_t_ - _t167_x1ˍt_t_*_tpa_ + _t167_x1_t_*_t167_x2ˍt_t_*_tpb_ + _t167_x1ˍt_t_*_t167_x2_t_*_tpb_
]

