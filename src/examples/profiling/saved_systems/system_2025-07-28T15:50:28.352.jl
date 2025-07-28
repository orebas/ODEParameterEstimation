# Polynomial system saved on 2025-07-28T15:50:28.353
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:50:28.352
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
    -4.591122138081465 + _t112_x2_t_,
    -4.4569321533906 + _t112_x2ˍt_t_,
    -4.963448316487807 + _t112_x1_t_,
    13.06391783108829 + _t112_x1ˍt_t_,
    _t112_x2ˍt_t_ + _t112_x2_t_*_tpc_ - _t112_x1_t_*_t112_x2_t_*_tpd_,
    _t112_x1ˍt_t_ - _t112_x1_t_*_tpa_ + _t112_x1_t_*_t112_x2_t_*_tpb_,
    -0.37493044604233794 + _t179_x2_t_,
    0.3344086867692253 + _t179_x2ˍt_t_,
    -2.6350914735898217 + _t179_x1_t_,
    -3.063456734073479 + _t179_x1ˍt_t_,
    _t179_x2ˍt_t_ + _t179_x2_t_*_tpc_ - _t179_x1_t_*_t179_x2_t_*_tpd_,
    _t179_x1ˍt_t_ - _t179_x1_t_*_tpa_ + _t179_x1_t_*_t179_x2_t_*_tpb_
]

