# Polynomial system saved on 2025-07-28T15:39:34.306
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:39:34.305
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t112_x1_t_
_t112_x2_t_
_t112_x2ˍt_t_
_t112_x2ˍtt_t_
_t112_x1ˍt_t_
_t112_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t112_x1_t_ _t112_x2_t_ _t112_x2ˍt_t_ _t112_x2ˍtt_t_ _t112_x1ˍt_t_ _t112_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t112_x1_t__t112_x2_t__t112_x2ˍt_t__t112_x2ˍtt_t__t112_x1ˍt_t__t112_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -4.591122131791584 + _t112_x2_t_,
    -4.4569317614446575 + _t112_x2ˍt_t_,
    43.65695474356762 + _t112_x2ˍtt_t_,
    -4.963448326624969 + _t112_x1_t_,
    13.063917293583422 + _t112_x1ˍt_t_,
    -14.47608809308346 + _t112_x1ˍtt_t_,
    _t112_x2ˍt_t_ + _t112_x2_t_*_tpc_ - _t112_x1_t_*_t112_x2_t_*_tpd_,
    _t112_x2ˍtt_t_ + _t112_x2ˍt_t_*_tpc_ - _t112_x1_t_*_t112_x2ˍt_t_*_tpd_ - _t112_x1ˍt_t_*_t112_x2_t_*_tpd_,
    _t112_x1ˍt_t_ - _t112_x1_t_*_tpa_ + _t112_x1_t_*_t112_x2_t_*_tpb_,
    _t112_x1ˍtt_t_ - _t112_x1ˍt_t_*_tpa_ + _t112_x1_t_*_t112_x2ˍt_t_*_tpb_ + _t112_x1ˍt_t_*_t112_x2_t_*_tpb_
]

