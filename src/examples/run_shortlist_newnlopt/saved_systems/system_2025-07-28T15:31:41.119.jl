# Polynomial system saved on 2025-07-28T15:31:41.119
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:31:41.119
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t223_x1_t_
_t223_x2_t_
_t223_x2ˍt_t_
_t223_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t223_x1_t_ _t223_x2_t_ _t223_x2ˍt_t_ _t223_x1ˍt_t_
varlist = [_tpa__tpb__t223_x1_t__t223_x2_t__t223_x2ˍt_t__t223_x1ˍt_t_]

# Polynomial System
poly_system = [
    2.297717068356165 + _t223_x2_t_,
    2.1283847249533236 + _t223_x2ˍt_t_,
    0.13031283746959504 + _t223_x1_t_,
    2.2977168813801687 + _t223_x1ˍt_t_,
    _t223_x1_t_ + _t223_x2ˍt_t_ + (-1 + _t223_x1_t_^2)*_t223_x2_t_*_tpb_,
    _t223_x1ˍt_t_ - _t223_x2_t_*_tpa_
]

