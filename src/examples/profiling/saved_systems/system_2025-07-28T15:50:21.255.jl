# Polynomial system saved on 2025-07-28T15:50:21.256
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:50:21.255
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
    -0.48342638208853206 + _t45_x2_t_,
    0.6565350709472373 + _t45_x2ˍt_t_,
    -2.0523687983407153 + _t45_x1_t_,
    -2.1855910862864167 + _t45_x1ˍt_t_,
    _t45_x2ˍt_t_ + _t45_x2_t_*_tpc_ - _t45_x1_t_*_t45_x2_t_*_tpd_,
    _t45_x1ˍt_t_ - _t45_x1_t_*_tpa_ + _t45_x1_t_*_t45_x2_t_*_tpb_,
    -4.591122096871903 + _t112_x2_t_,
    -4.456932057820862 + _t112_x2ˍt_t_,
    -4.963448319797901 + _t112_x1_t_,
    13.063916735025078 + _t112_x1ˍt_t_,
    _t112_x2ˍt_t_ + _t112_x2_t_*_tpc_ - _t112_x1_t_*_t112_x2_t_*_tpd_,
    _t112_x1ˍt_t_ - _t112_x1_t_*_tpa_ + _t112_x1_t_*_t112_x2_t_*_tpb_
]

