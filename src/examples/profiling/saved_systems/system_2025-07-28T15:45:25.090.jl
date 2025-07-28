# Polynomial system saved on 2025-07-28T15:45:25.090
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:45:25.090
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
    2.205868927891973 + 3.0_t67_x1_t_ - 0.25_t67_x2_t_,
    -0.0805903902135896 + 2.0_t67_x1_t_ + 0.5_t67_x2_t_,
    2.077960915267895 + 2.0_t67_x1ˍt_t_ + 0.5_t67_x2ˍt_t_,
    _t67_x1ˍt_t_ + _t67_x2_t_*_tpa_,
    _t67_x2ˍt_t_ - _t67_x1_t_*_tpb_,
    5.13986189406992 + 3.0_t134_x1_t_ - 0.25_t134_x2_t_,
    2.9356183730294214 + 2.0_t134_x1_t_ + 0.5_t134_x2_t_,
    1.2499144815698835 + 2.0_t134_x1ˍt_t_ + 0.5_t134_x2ˍt_t_,
    _t134_x1ˍt_t_ + _t134_x2_t_*_tpa_,
    _t134_x2ˍt_t_ - _t134_x1_t_*_tpb_
]

