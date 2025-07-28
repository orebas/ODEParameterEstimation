# Polynomial system saved on 2025-07-28T15:49:45.808
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:49:45.808
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t89_x1_t_
_t89_x2_t_
_t89_x2ˍt_t_
_t89_x2ˍtt_t_
_t89_x1ˍt_t_
_t89_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t89_x1_t_ _t89_x2_t_ _t89_x2ˍt_t_ _t89_x2ˍtt_t_ _t89_x1ˍt_t_ _t89_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t89_x1_t__t89_x2_t__t89_x2ˍt_t__t89_x2ˍtt_t__t89_x1ˍt_t__t89_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -0.4678908618762645 + _t89_x2_t_,
    0.615044827567202 + _t89_x2ˍt_t_,
    -1.6591158137159565 + _t89_x2ˍtt_t_,
    -2.1068522374961676 + _t89_x1_t_,
    -2.2730719517735487 + _t89_x1ˍt_t_,
    -3.6188737274871454 + _t89_x1ˍtt_t_,
    _t89_x2ˍt_t_ + _t89_x2_t_*_tpc_ - _t89_x1_t_*_t89_x2_t_*_tpd_,
    _t89_x2ˍtt_t_ + _t89_x2ˍt_t_*_tpc_ - _t89_x1_t_*_t89_x2ˍt_t_*_tpd_ - _t89_x1ˍt_t_*_t89_x2_t_*_tpd_,
    _t89_x1ˍt_t_ - _t89_x1_t_*_tpa_ + _t89_x1_t_*_t89_x2_t_*_tpb_,
    _t89_x1ˍtt_t_ - _t89_x1ˍt_t_*_tpa_ + _t89_x1_t_*_t89_x2ˍt_t_*_tpb_ + _t89_x1ˍt_t_*_t89_x2_t_*_tpb_
]

