# Polynomial system saved on 2025-07-28T15:39:52.843
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:39:52.842
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t134_x1_t_
_t134_x2_t_
_t134_x2ˍt_t_
_t134_x1ˍt_t_
_t201_x1_t_
_t201_x2_t_
_t201_x2ˍt_t_
_t201_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t134_x1_t_ _t134_x2_t_ _t134_x2ˍt_t_ _t134_x1ˍt_t_ _t201_x1_t_ _t201_x2_t_ _t201_x2ˍt_t_ _t201_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t134_x1_t__t134_x2_t__t134_x2ˍt_t__t134_x1ˍt_t__t201_x1_t__t201_x2_t__t201_x2ˍt_t__t201_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.41446695170145986 + _t134_x2_t_,
    0.46376452840215765 + _t134_x2ˍt_t_,
    -2.3513386900370703 + _t134_x1_t_,
    -2.649917227311389 + _t134_x1ˍt_t_,
    _t134_x2ˍt_t_ + _t134_x2_t_*_tpc_ - _t134_x1_t_*_t134_x2_t_*_tpd_,
    _t134_x1ˍt_t_ - _t134_x1_t_*_tpa_ + _t134_x1_t_*_t134_x2_t_*_tpb_,
    -4.804236550806808 + _t201_x2_t_,
    0.8942471974472438 + _t201_x2ˍt_t_,
    -3.5181616035543977 + _t201_x1_t_,
    9.928171858311035 + _t201_x1ˍt_t_,
    _t201_x2ˍt_t_ + _t201_x2_t_*_tpc_ - _t201_x1_t_*_t201_x2_t_*_tpd_,
    _t201_x1ˍt_t_ - _t201_x1_t_*_tpa_ + _t201_x1_t_*_t201_x2_t_*_tpb_
]

