# Polynomial system saved on 2025-07-28T15:39:47.524
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:39:47.524
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t45_x1_t_
_t45_x2_t_
_t45_x2ˍt_t_
_t45_x1ˍt_t_
_t112_x1_t_
_t112_x2_t_
_t112_x2ˍt_t_
_t112_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t45_x1_t_ _t45_x2_t_ _t45_x2ˍt_t_ _t45_x1ˍt_t_ _t112_x1_t_ _t112_x2_t_ _t112_x2ˍt_t_ _t112_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t45_x1_t__t45_x2_t__t45_x2ˍt_t__t45_x1ˍt_t__t112_x1_t__t112_x2_t__t112_x2ˍt_t__t112_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.48342639968045686 + _t45_x2_t_,
    0.656534696224941 + _t45_x2ˍt_t_,
    -2.052368763640761 + _t45_x1_t_,
    -2.1855915064033065 + _t45_x1ˍt_t_,
    _t45_x2ˍt_t_ + _t45_x2_t_*_tpc_ - _t45_x1_t_*_t45_x2_t_*_tpd_,
    _t45_x1ˍt_t_ - _t45_x1_t_*_tpa_ + _t45_x1_t_*_t45_x2_t_*_tpb_,
    -4.591122112748429 + _t112_x2_t_,
    -4.4569314938532365 + _t112_x2ˍt_t_,
    -4.963448335520846 + _t112_x1_t_,
    13.063917020844398 + _t112_x1ˍt_t_,
    _t112_x2ˍt_t_ + _t112_x2_t_*_tpc_ - _t112_x1_t_*_t112_x2_t_*_tpd_,
    _t112_x1ˍt_t_ - _t112_x1_t_*_tpa_ + _t112_x1_t_*_t112_x2_t_*_tpb_
]

