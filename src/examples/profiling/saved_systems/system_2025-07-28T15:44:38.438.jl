# Polynomial system saved on 2025-07-28T15:44:38.438
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:44:38.438
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
    -0.6598791575709129 + _t89_x2_t_,
    0.2720155810809972 + _t89_x2ˍt_t_,
    0.34001947265127497 + _t89_x1_t_,
    0.2639515963985884 + _t89_x1ˍt_t_,
    _t89_x2ˍt_t_ - _t89_x1_t_*_tpb_,
    _t89_x1ˍt_t_ + _t89_x2_t_*_tpa_
]

