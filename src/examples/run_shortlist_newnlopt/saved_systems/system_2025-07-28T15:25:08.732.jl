# Polynomial system saved on 2025-07-28T15:25:08.732
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:25:08.732
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t111_x1_t_
_t111_x2_t_
_t111_x2ˍt_t_
_t111_x2ˍtt_t_
_t111_x1ˍt_t_
_t111_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t111_x1_t_ _t111_x2_t_ _t111_x2ˍt_t_ _t111_x2ˍtt_t_ _t111_x1ˍt_t_ _t111_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t111_x1_t__t111_x2_t__t111_x2ˍt_t__t111_x2ˍtt_t__t111_x1ˍt_t__t111_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -0.4834263955264211 + _t111_x2_t_,
    0.6565435661652542 + _t111_x2ˍt_t_,
    -1.7369237410386054 + _t111_x2ˍtt_t_,
    -2.0523687426327255 + _t111_x1_t_,
    -2.185600805463253 + _t111_x1ˍt_t_,
    -3.540202144713864 + _t111_x1ˍtt_t_,
    _t111_x2ˍt_t_ + _t111_x2_t_*_tpc_ - _t111_x1_t_*_t111_x2_t_*_tpd_,
    _t111_x2ˍtt_t_ + _t111_x2ˍt_t_*_tpc_ - _t111_x1_t_*_t111_x2ˍt_t_*_tpd_ - _t111_x1ˍt_t_*_t111_x2_t_*_tpd_,
    _t111_x1ˍt_t_ - _t111_x1_t_*_tpa_ + _t111_x1_t_*_t111_x2_t_*_tpb_,
    _t111_x1ˍtt_t_ - _t111_x1ˍt_t_*_tpa_ + _t111_x1_t_*_t111_x2ˍt_t_*_tpb_ + _t111_x1ˍt_t_*_t111_x2_t_*_tpb_
]

