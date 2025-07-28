# Polynomial system saved on 2025-07-28T15:31:21.451
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:31:21.450
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t501_x1_t_
_t501_x2_t_
_t501_x2ˍt_t_
_t501_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t501_x1_t_ _t501_x2_t_ _t501_x2ˍt_t_ _t501_x1ˍt_t_
varlist = [_tpa__tpb__t501_x1_t__t501_x2_t__t501_x2ˍt_t__t501_x1ˍt_t_]

# Polynomial System
poly_system = [
    -1.3070889377996737 + _t501_x2_t_,
    -1.2282909237659396 + _t501_x2ˍt_t_,
    0.837077450294763 + _t501_x1_t_,
    -1.3070889377934627 + _t501_x1ˍt_t_,
    _t501_x1_t_ + _t501_x2ˍt_t_ + (-1 + _t501_x1_t_^2)*_t501_x2_t_*_tpb_,
    _t501_x1ˍt_t_ - _t501_x2_t_*_tpa_
]

