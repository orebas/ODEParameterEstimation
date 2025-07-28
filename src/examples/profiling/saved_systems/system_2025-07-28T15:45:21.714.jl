# Polynomial system saved on 2025-07-28T15:45:21.716
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:45:21.714
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t22_x1_t_
_t22_x2_t_
_t22_x1ˍt_t_
_t22_x2ˍt_t_
_t89_x1_t_
_t89_x2_t_
_t89_x1ˍt_t_
_t89_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t22_x1_t_ _t22_x2_t_ _t22_x1ˍt_t_ _t22_x2ˍt_t_ _t89_x1_t_ _t89_x2_t_ _t89_x1ˍt_t_ _t89_x2ˍt_t_
varlist = [_tpa__tpb__t22_x1_t__t22_x2_t__t22_x1ˍt_t__t22_x2ˍt_t__t89_x1_t__t89_x2_t__t89_x1ˍt_t__t89_x2ˍt_t_]

# Polynomial System
poly_system = [
    -1.0455351393761902 + 3.0_t22_x1_t_ - 0.25_t22_x2_t_,
    -2.2478897792914485 + 2.0_t22_x1_t_ + 0.5_t22_x2_t_,
    1.6440916483092638 + 2.0_t22_x1ˍt_t_ + 0.5_t22_x2ˍt_t_,
    _t22_x1ˍt_t_ + _t22_x2_t_*_tpa_,
    _t22_x2ˍt_t_ - _t22_x1_t_*_tpb_,
    3.5523685519872608 + 3.0_t89_x1_t_ - 0.25_t89_x2_t_,
    1.047807990256929 + 2.0_t89_x1_t_ + 0.5_t89_x2_t_,
    1.9921524689747772 + 2.0_t89_x1ˍt_t_ + 0.5_t89_x2ˍt_t_,
    _t89_x1ˍt_t_ + _t89_x2_t_*_tpa_,
    _t89_x2ˍt_t_ - _t89_x1_t_*_tpb_
]

