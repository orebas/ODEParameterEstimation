# Polynomial system saved on 2025-07-28T15:50:19.858
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:50:19.857
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t22_x1_t_
_t22_x2_t_
_t22_x2ˍt_t_
_t22_x1ˍt_t_
_t89_x1_t_
_t89_x2_t_
_t89_x2ˍt_t_
_t89_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t22_x1_t_ _t22_x2_t_ _t22_x2ˍt_t_ _t22_x1ˍt_t_ _t89_x1_t_ _t89_x2_t_ _t89_x2ˍt_t_ _t89_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t22_x1_t__t22_x2_t__t22_x2ˍt_t__t22_x1ˍt_t__t89_x1_t__t89_x2_t__t89_x2ˍt_t__t89_x1ˍt_t_]

# Polynomial System
poly_system = [
    -3.0826240821182225 + _t22_x2_t_,
    -9.057671825671692 + _t22_x2ˍt_t_,
    -7.42284674628472 + _t22_x1_t_,
    9.459471332084211 + _t22_x1ˍt_t_,
    _t22_x2ˍt_t_ + _t22_x2_t_*_tpc_ - _t22_x1_t_*_t22_x2_t_*_tpd_,
    _t22_x1ˍt_t_ - _t22_x1_t_*_tpa_ + _t22_x1_t_*_t22_x2_t_*_tpb_,
    -0.4678908506507258 + _t89_x2_t_,
    0.6150446799322175 + _t89_x2ˍt_t_,
    -2.106852267312872 + _t89_x1_t_,
    -2.2730726394838636 + _t89_x1ˍt_t_,
    _t89_x2ˍt_t_ + _t89_x2_t_*_tpc_ - _t89_x1_t_*_t89_x2_t_*_tpd_,
    _t89_x1ˍt_t_ - _t89_x1_t_*_tpa_ + _t89_x1_t_*_t89_x2_t_*_tpb_
]

