# Polynomial system saved on 2025-07-28T15:26:02.769
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:26:02.769
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t223_x1_t_
_t223_x2_t_
_t223_x2ˍt_t_
_t223_x2ˍtt_t_
_t223_x1ˍt_t_
_t223_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t223_x1_t_ _t223_x2_t_ _t223_x2ˍt_t_ _t223_x2ˍtt_t_ _t223_x1ˍt_t_ _t223_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t223_x1_t__t223_x2_t__t223_x2ˍt_t__t223_x2ˍtt_t__t223_x1ˍt_t__t223_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -0.43386890026835007 + _t223_x2_t_,
    0.5206873041045093 + _t223_x2ˍt_t_,
    -1.491322437291842 + _t223_x2ˍtt_t_,
    -2.2498714364511194 + _t223_x1_t_,
    -2.496272833386783 + _t223_x1ˍt_t_,
    -3.82399115953001 + _t223_x1ˍtt_t_,
    _t223_x2ˍt_t_ + _t223_x2_t_*_tpc_ - _t223_x1_t_*_t223_x2_t_*_tpd_,
    _t223_x2ˍtt_t_ + _t223_x2ˍt_t_*_tpc_ - _t223_x1_t_*_t223_x2ˍt_t_*_tpd_ - _t223_x1ˍt_t_*_t223_x2_t_*_tpd_,
    _t223_x1ˍt_t_ - _t223_x1_t_*_tpa_ + _t223_x1_t_*_t223_x2_t_*_tpb_,
    _t223_x1ˍtt_t_ - _t223_x1ˍt_t_*_tpa_ + _t223_x1_t_*_t223_x2ˍt_t_*_tpb_ + _t223_x1ˍt_t_*_t223_x2_t_*_tpb_
]

