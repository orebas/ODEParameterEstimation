# Polynomial system saved on 2025-07-28T15:30:40.453
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:30:40.453
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t167_x1_t_
_t167_x2_t_
_t167_x2ˍt_t_
_t167_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t167_x1_t_ _t167_x2_t_ _t167_x2ˍt_t_ _t167_x1ˍt_t_
varlist = [_tpa__tpb__t167_x1_t__t167_x2_t__t167_x2ˍt_t__t167_x1ˍt_t_]

# Polynomial System
poly_system = [
    1.2960627894347192 + _t167_x2_t_,
    1.2122178014050746 + _t167_x2ˍt_t_,
    -0.8478677044499272 + _t167_x1_t_,
    1.2960628009013715 + _t167_x1ˍt_t_,
    _t167_x1_t_ + _t167_x2ˍt_t_ + (-1 + _t167_x1_t_^2)*_t167_x2_t_*_tpb_,
    _t167_x1ˍt_t_ - _t167_x2_t_*_tpa_
]

