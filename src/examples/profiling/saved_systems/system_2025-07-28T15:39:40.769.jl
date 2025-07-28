# Polynomial system saved on 2025-07-28T15:39:40.769
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:39:40.769
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
    -0.46789064485640725 + _t89_x2_t_,
    0.6150506860089511 + _t89_x2ˍt_t_,
    -1.6593374313011964 + _t89_x2ˍtt_t_,
    -2.1068524697748523 + _t89_x1_t_,
    -2.2730798000316574 + _t89_x1ˍt_t_,
    -3.618661155116399 + _t89_x1ˍtt_t_,
    _t89_x2ˍt_t_ + _t89_x2_t_*_tpc_ - _t89_x1_t_*_t89_x2_t_*_tpd_,
    _t89_x2ˍtt_t_ + _t89_x2ˍt_t_*_tpc_ - _t89_x1_t_*_t89_x2ˍt_t_*_tpd_ - _t89_x1ˍt_t_*_t89_x2_t_*_tpd_,
    _t89_x1ˍt_t_ - _t89_x1_t_*_tpa_ + _t89_x1_t_*_t89_x2_t_*_tpb_,
    _t89_x1ˍtt_t_ - _t89_x1ˍt_t_*_tpa_ + _t89_x1_t_*_t89_x2ˍt_t_*_tpb_ + _t89_x1ˍt_t_*_t89_x2_t_*_tpb_
]

