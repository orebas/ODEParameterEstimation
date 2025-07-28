# Polynomial system saved on 2025-07-28T15:49:47.945
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:49:47.941
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t134_x1_t_
_t134_x2_t_
_t134_x2ˍt_t_
_t134_x2ˍtt_t_
_t134_x1ˍt_t_
_t134_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t134_x1_t_ _t134_x2_t_ _t134_x2ˍt_t_ _t134_x2ˍtt_t_ _t134_x1ˍt_t_ _t134_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t134_x1_t__t134_x2_t__t134_x2ˍt_t__t134_x2ˍtt_t__t134_x1ˍt_t__t134_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -0.41446697826807144 + _t134_x2_t_,
    0.4637644907326125 + _t134_x2ˍt_t_,
    -1.3977970444280625 + _t134_x2ˍtt_t_,
    -2.3513386925993762 + _t134_x1_t_,
    -2.649916817498903 + _t134_x1ˍt_t_,
    -3.9675540007701504 + _t134_x1ˍtt_t_,
    _t134_x2ˍt_t_ + _t134_x2_t_*_tpc_ - _t134_x1_t_*_t134_x2_t_*_tpd_,
    _t134_x2ˍtt_t_ + _t134_x2ˍt_t_*_tpc_ - _t134_x1_t_*_t134_x2ˍt_t_*_tpd_ - _t134_x1ˍt_t_*_t134_x2_t_*_tpd_,
    _t134_x1ˍt_t_ - _t134_x1_t_*_tpa_ + _t134_x1_t_*_t134_x2_t_*_tpb_,
    _t134_x1ˍtt_t_ - _t134_x1ˍt_t_*_tpa_ + _t134_x1_t_*_t134_x2ˍt_t_*_tpb_ + _t134_x1ˍt_t_*_t134_x2_t_*_tpb_
]

