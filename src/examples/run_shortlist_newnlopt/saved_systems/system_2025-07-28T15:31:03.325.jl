# Polynomial system saved on 2025-07-28T15:31:03.326
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:31:03.325
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t111_x1_t_
_t111_x2_t_
_t111_x2ˍt_t_
_t111_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t111_x1_t_ _t111_x2_t_ _t111_x2ˍt_t_ _t111_x1ˍt_t_
varlist = [_tpa__tpb__t111_x1_t__t111_x2_t__t111_x2ˍt_t__t111_x1ˍt_t_]

# Polynomial System
poly_system = [
    0.833875488091159 + _t111_x2_t_,
    0.5621682604371436 + _t111_x2ˍt_t_,
    -1.427479894277815 + _t111_x1_t_,
    0.8338754880916923 + _t111_x1ˍt_t_,
    _t111_x1_t_ + _t111_x2ˍt_t_ + (-1 + _t111_x1_t_^2)*_t111_x2_t_*_tpb_,
    _t111_x1ˍt_t_ - _t111_x2_t_*_tpa_
]

