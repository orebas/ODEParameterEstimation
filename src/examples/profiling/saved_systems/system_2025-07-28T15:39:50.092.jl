# Polynomial system saved on 2025-07-28T15:39:50.093
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:39:50.092
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t67_x1_t_
_t67_x2_t_
_t67_x2ˍt_t_
_t67_x1ˍt_t_
_t134_x1_t_
_t134_x2_t_
_t134_x2ˍt_t_
_t134_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t67_x1_t_ _t67_x2_t_ _t67_x2ˍt_t_ _t67_x1ˍt_t_ _t134_x1_t_ _t134_x2_t_ _t134_x2ˍt_t_ _t134_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t67_x1_t__t67_x2_t__t67_x2ˍt_t__t67_x1ˍt_t__t134_x1_t__t134_x2_t__t134_x2ˍt_t__t134_x1ˍt_t_]

# Polynomial System
poly_system = [
    -3.955033448558221 + _t67_x2_t_,
    -8.018093659519378 + _t67_x2ˍt_t_,
    -6.2841632225578365 + _t67_x1_t_,
    12.942342980312278 + _t67_x1ˍt_t_,
    _t67_x2ˍt_t_ + _t67_x2_t_*_tpc_ - _t67_x1_t_*_t67_x2_t_*_tpd_,
    _t67_x1ˍt_t_ - _t67_x1_t_*_tpa_ + _t67_x1_t_*_t67_x2_t_*_tpb_,
    -0.41446697059550175 + _t134_x2_t_,
    0.4637647351136232 + _t134_x2ˍt_t_,
    -2.351338658448949 + _t134_x1_t_,
    -2.6499168127541783 + _t134_x1ˍt_t_,
    _t134_x2ˍt_t_ + _t134_x2_t_*_tpc_ - _t134_x1_t_*_t134_x2_t_*_tpd_,
    _t134_x1ˍt_t_ - _t134_x1_t_*_tpa_ + _t134_x1_t_*_t134_x2_t_*_tpb_
]

