# Polynomial system saved on 2025-07-28T15:50:23.738
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:50:23.737
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
    -3.9550334403813765 + _t67_x2_t_,
    -8.01809325787821 + _t67_x2ˍt_t_,
    -6.284163215903169 + _t67_x1_t_,
    12.942343393328617 + _t67_x1ˍt_t_,
    _t67_x2ˍt_t_ + _t67_x2_t_*_tpc_ - _t67_x1_t_*_t67_x2_t_*_tpd_,
    _t67_x1ˍt_t_ - _t67_x1_t_*_tpa_ + _t67_x1_t_*_t67_x2_t_*_tpb_,
    -0.41446696665077054 + _t134_x2_t_,
    0.4637644783078852 + _t134_x2ˍt_t_,
    -2.351338697471851 + _t134_x1_t_,
    -2.6499167542944795 + _t134_x1ˍt_t_,
    _t134_x2ˍt_t_ + _t134_x2_t_*_tpc_ - _t134_x1_t_*_t134_x2_t_*_tpd_,
    _t134_x1ˍt_t_ - _t134_x1_t_*_tpa_ + _t134_x1_t_*_t134_x2_t_*_tpb_
]

