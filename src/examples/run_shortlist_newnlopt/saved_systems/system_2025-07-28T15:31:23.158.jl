# Polynomial system saved on 2025-07-28T15:31:23.158
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:31:23.158
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t56_x1_t_
_t56_x2_t_
_t56_x2ˍt_t_
_t56_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t56_x1_t_ _t56_x2_t_ _t56_x2ˍt_t_ _t56_x1ˍt_t_
varlist = [_tpa__tpb__t56_x1_t__t56_x2_t__t56_x2ˍt_t__t56_x1ˍt_t_]

# Polynomial System
poly_system = [
    0.5619241681259822 + _t56_x2_t_,
    0.5306938298755017 + _t56_x2ˍt_t_,
    -1.8103004473295625 + _t56_x1_t_,
    0.5619242499912112 + _t56_x1ˍt_t_,
    _t56_x1_t_ + _t56_x2ˍt_t_ + (-1 + _t56_x1_t_^2)*_t56_x2_t_*_tpb_,
    _t56_x1ˍt_t_ - _t56_x2_t_*_tpa_
]

