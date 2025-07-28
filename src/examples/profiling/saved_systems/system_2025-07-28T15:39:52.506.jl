# Polynomial system saved on 2025-07-28T15:39:52.506
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:39:52.506
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t112_x1_t_
_t112_x2_t_
_t112_x2ˍt_t_
_t112_x1ˍt_t_
_t179_x1_t_
_t179_x2_t_
_t179_x2ˍt_t_
_t179_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t112_x1_t_ _t112_x2_t_ _t112_x2ˍt_t_ _t112_x1ˍt_t_ _t179_x1_t_ _t179_x2_t_ _t179_x2ˍt_t_ _t179_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t112_x1_t__t112_x2_t__t112_x2ˍt_t__t112_x1ˍt_t__t179_x1_t__t179_x2_t__t179_x2ˍt_t__t179_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.5911220970454165 + _t112_x2_t_,
    -4.45693208566968 + _t112_x2ˍt_t_,
    -4.9634483191082985 + _t112_x1_t_,
    13.063917558071108 + _t112_x1ˍt_t_,
    _t112_x2ˍt_t_ + _t112_x2_t_*_tpc_ - _t112_x1_t_*_t112_x2_t_*_tpd_,
    _t112_x1ˍt_t_ - _t112_x1_t_*_tpa_ + _t112_x1_t_*_t112_x2_t_*_tpb_,
    -0.37493045160140004 + _t179_x2_t_,
    0.33440855673707603 + _t179_x2ˍt_t_,
    -2.6350914327542947 + _t179_x1_t_,
    -3.0634574038209603 + _t179_x1ˍt_t_,
    _t179_x2ˍt_t_ + _t179_x2_t_*_tpc_ - _t179_x1_t_*_t179_x2_t_*_tpd_,
    _t179_x1ˍt_t_ - _t179_x1_t_*_tpa_ + _t179_x1_t_*_t179_x2_t_*_tpb_
]

