# Polynomial system saved on 2025-07-28T15:36:14.499
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:36:14.498
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t89_x1_t_
_t89_x2_t_
_t89_x1ˍt_t_
_t89_x2ˍt_t_
_t156_x1_t_
_t156_x2_t_
_t156_x1ˍt_t_
_t156_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t89_x1_t_ _t89_x2_t_ _t89_x1ˍt_t_ _t89_x2ˍt_t_ _t156_x1_t_ _t156_x2_t_ _t156_x1ˍt_t_ _t156_x2ˍt_t_
varlist = [_tpa__tpb__t89_x1_t__t89_x2_t__t89_x1ˍt_t__t89_x2ˍt_t__t156_x1_t__t156_x2_t__t156_x1ˍt_t__t156_x2ˍt_t_]

# Polynomial System
poly_system = [
    3.552368524942092 + 3.0_t89_x1_t_ - 0.25_t89_x2_t_,
    1.0478079612152622 + 2.0_t89_x1_t_ + 0.5_t89_x2_t_,
    1.9921524460431452 + 2.0_t89_x1ˍt_t_ + 0.5_t89_x2ˍt_t_,
    _t89_x1ˍt_t_ + _t89_x2_t_*_tpa_,
    _t89_x2ˍt_t_ - _t89_x1_t_*_tpb_,
    5.19254216945548 + 3.0_t156_x1_t_ - 0.25_t156_x2_t_,
    3.471092620141242 + 2.0_t156_x1_t_ + 0.5_t156_x2_t_,
    0.6815314482607298 + 2.0_t156_x1ˍt_t_ + 0.5_t156_x2ˍt_t_,
    _t156_x1ˍt_t_ + _t156_x2_t_*_tpa_,
    _t156_x2ˍt_t_ - _t156_x1_t_*_tpb_
]

