# Polynomial system saved on 2025-07-28T15:36:15.545
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:36:15.545
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
    5.1398618997728285 + 3.0_t134_x1_t_ - 0.25_t134_x2_t_,
    2.9356184980794158 + 2.0_t134_x1_t_ + 0.5_t134_x2_t_,
    1.249914414609519 + 2.0_t134_x1ˍt_t_ + 0.5_t134_x2ˍt_t_,
    _t134_x1ˍt_t_ + _t134_x2_t_*_tpa_,
    _t134_x2ˍt_t_ - _t134_x1_t_*_tpb_,
    3.7943653801605266 + 3.0_t201_x1_t_ - 0.25_t201_x2_t_,
    3.5076082858859223 + 2.0_t201_x1_t_ + 0.5_t201_x2_t_,
    -0.6188199296147213 + 2.0_t201_x1ˍt_t_ + 0.5_t201_x2ˍt_t_,
    _t201_x1ˍt_t_ + _t201_x2_t_*_tpa_,
    _t201_x2ˍt_t_ - _t201_x1_t_*_tpb_
]

