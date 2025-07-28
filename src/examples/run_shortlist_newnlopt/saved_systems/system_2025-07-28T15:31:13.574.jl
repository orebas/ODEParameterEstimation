# Polynomial system saved on 2025-07-28T15:31:13.575
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:31:13.574
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t334_x1_t_
_t334_x2_t_
_t334_x2ˍt_t_
_t334_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t334_x1_t_ _t334_x2_t_ _t334_x2ˍt_t_ _t334_x1ˍt_t_
varlist = [_tpa__tpb__t334_x1_t__t334_x2_t__t334_x2ˍt_t__t334_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.019272746909752586 + _t334_x2_t_,
    -1.9498102220277187 + _t334_x2ˍt_t_,
    2.008267098754977 + _t334_x1_t_,
    -0.01927274690996228 + _t334_x1ˍt_t_,
    _t334_x1_t_ + _t334_x2ˍt_t_ + (-1 + _t334_x1_t_^2)*_t334_x2_t_*_tpb_,
    _t334_x1ˍt_t_ - _t334_x2_t_*_tpa_
]

