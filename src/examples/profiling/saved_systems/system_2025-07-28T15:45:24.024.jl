# Polynomial system saved on 2025-07-28T15:45:24.024
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:45:24.024
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t67_x1_t_
_t67_x2_t_
_t67_x1ˍt_t_
_t67_x2ˍt_t_
_t134_x1_t_
_t134_x2_t_
_t134_x1ˍt_t_
_t134_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t67_x1_t_ _t67_x2_t_ _t67_x1ˍt_t_ _t67_x2ˍt_t_ _t134_x1_t_ _t134_x2_t_ _t134_x1ˍt_t_ _t134_x2ˍt_t_
varlist = [_tpa__tpb__t67_x1_t__t67_x2_t__t67_x1ˍt_t__t67_x2ˍt_t__t134_x1_t__t134_x2_t__t134_x1ˍt_t__t134_x2ˍt_t_]

# Polynomial System
poly_system = [
    2.2058690271690025 + 3.0_t67_x1_t_ - 0.25_t67_x2_t_,
    -0.08059031512636428 + 2.0_t67_x1_t_ + 0.5_t67_x2_t_,
    2.0779609615242722 + 2.0_t67_x1ˍt_t_ + 0.5_t67_x2ˍt_t_,
    _t67_x1ˍt_t_ + _t67_x2_t_*_tpa_,
    _t67_x2ˍt_t_ - _t67_x1_t_*_tpb_,
    5.139861940894807 + 3.0_t134_x1_t_ - 0.25_t134_x2_t_,
    2.9356184982088545 + 2.0_t134_x1_t_ + 0.5_t134_x2_t_,
    1.2499144725937876 + 2.0_t134_x1ˍt_t_ + 0.5_t134_x2ˍt_t_,
    _t134_x1ˍt_t_ + _t134_x2_t_*_tpa_,
    _t134_x2ˍt_t_ - _t134_x1_t_*_tpb_
]

