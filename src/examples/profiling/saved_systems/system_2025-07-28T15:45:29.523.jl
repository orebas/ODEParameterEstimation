# Polynomial system saved on 2025-07-28T15:45:29.524
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:45:29.523
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t134_x1_t_
_t134_x2_t_
_t134_x1ˍt_t_
_t134_x2ˍt_t_
_t201_x1_t_
_t201_x2_t_
_t201_x1ˍt_t_
_t201_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t134_x1_t_ _t134_x2_t_ _t134_x1ˍt_t_ _t134_x2ˍt_t_ _t201_x1_t_ _t201_x2_t_ _t201_x1ˍt_t_ _t201_x2ˍt_t_
varlist = [_tpa__tpb__t134_x1_t__t134_x2_t__t134_x1ˍt_t__t134_x2ˍt_t__t201_x1_t__t201_x2_t__t201_x1ˍt_t__t201_x2ˍt_t_]

# Polynomial System
poly_system = [
    5.139861876443183 + 3.0_t134_x1_t_ - 0.25_t134_x2_t_,
    2.9356184142262327 + 2.0_t134_x1_t_ + 0.5_t134_x2_t_,
    1.2499144826181867 + 2.0_t134_x1ˍt_t_ + 0.5_t134_x2ˍt_t_,
    _t134_x1ˍt_t_ + _t134_x2_t_*_tpa_,
    _t134_x2ˍt_t_ - _t134_x1_t_*_tpb_,
    3.7943652737303726 + 3.0_t201_x1_t_ - 0.25_t201_x2_t_,
    3.5076081186640256 + 2.0_t201_x1_t_ + 0.5_t201_x2_t_,
    -0.6188210570576094 + 2.0_t201_x1ˍt_t_ + 0.5_t201_x2ˍt_t_,
    _t201_x1ˍt_t_ + _t201_x2_t_*_tpa_,
    _t201_x2ˍt_t_ - _t201_x1_t_*_tpb_
]

