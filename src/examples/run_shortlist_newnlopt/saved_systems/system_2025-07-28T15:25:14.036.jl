# Polynomial system saved on 2025-07-28T15:25:14.045
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:25:14.036
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
    -0.43386892383353026 + _t223_x2_t_,
    0.5206874033111267 + _t223_x2ˍt_t_,
    -1.4913006642684088 + _t223_x2ˍtt_t_,
    -2.2498714205955013 + _t223_x1_t_,
    -2.496272643417783 + _t223_x1ˍt_t_,
    -3.8239851197342127 + _t223_x1ˍtt_t_,
    _t223_x2ˍt_t_ + _t223_x2_t_*_tpc_ - _t223_x1_t_*_t223_x2_t_*_tpd_,
    _t223_x2ˍtt_t_ + _t223_x2ˍt_t_*_tpc_ - _t223_x1_t_*_t223_x2ˍt_t_*_tpd_ - _t223_x1ˍt_t_*_t223_x2_t_*_tpd_,
    _t223_x1ˍt_t_ - _t223_x1_t_*_tpa_ + _t223_x1_t_*_t223_x2_t_*_tpb_,
    _t223_x1ˍtt_t_ - _t223_x1ˍt_t_*_tpa_ + _t223_x1_t_*_t223_x2ˍt_t_*_tpb_ + _t223_x1ˍt_t_*_t223_x2_t_*_tpb_
]

