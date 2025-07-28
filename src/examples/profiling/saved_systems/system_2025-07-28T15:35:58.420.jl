# Polynomial system saved on 2025-07-28T15:35:58.420
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:35:58.420
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t89_x1_t_
_t89_x2_t_
_t89_x2ˍt_t_
_t89_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t89_x1_t_ _t89_x2_t_ _t89_x2ˍt_t_ _t89_x1ˍt_t_
varlist = [_tpa__tpb__t89_x1_t__t89_x2_t__t89_x2ˍt_t__t89_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.6598791427155719 + _t89_x2_t_,
    0.27201559237619666 + _t89_x2ˍt_t_,
    0.3400194905212651 + _t89_x1_t_,
    0.2639516505514728 + _t89_x1ˍt_t_,
    _t89_x2ˍt_t_ - _t89_x1_t_*_tpb_,
    _t89_x1ˍt_t_ + _t89_x2_t_*_tpa_
]

