# Polynomial system saved on 2025-07-28T15:50:18.486
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:50:18.486
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
    -3.082624082095178 + _t22_x2_t_,
    -9.057672601842192 + _t22_x2ˍt_t_,
    -7.422846727337881 + _t22_x1_t_,
    9.45947201055573 + _t22_x1ˍt_t_,
    _t22_x2ˍt_t_ + _t22_x2_t_*_tpc_ - _t22_x1_t_*_t22_x2_t_*_tpd_,
    _t22_x1ˍt_t_ - _t22_x1_t_*_tpa_ + _t22_x1_t_*_t22_x2_t_*_tpb_,
    -0.4678908426907735 + _t89_x2_t_,
    0.6150445693267931 + _t89_x2ˍt_t_,
    -2.1068523200287013 + _t89_x1_t_,
    -2.273072857990233 + _t89_x1ˍt_t_,
    _t89_x2ˍt_t_ + _t89_x2_t_*_tpc_ - _t89_x1_t_*_t89_x2_t_*_tpd_,
    _t89_x1ˍt_t_ - _t89_x1_t_*_tpa_ + _t89_x1_t_*_t89_x2_t_*_tpb_
]

