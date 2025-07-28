# Polynomial system saved on 2025-07-28T15:39:51.006
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:39:51.006
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
    -3.955033446237472 + _t67_x2_t_,
    -8.018093349627286 + _t67_x2ˍt_t_,
    -6.284163213592999 + _t67_x1_t_,
    12.942343442682803 + _t67_x1ˍt_t_,
    _t67_x2ˍt_t_ + _t67_x2_t_*_tpc_ - _t67_x1_t_*_t67_x2_t_*_tpd_,
    _t67_x1ˍt_t_ - _t67_x1_t_*_tpa_ + _t67_x1_t_*_t67_x2_t_*_tpb_,
    -0.4144669925680604 + _t134_x2_t_,
    0.4637647791099218 + _t134_x2ˍt_t_,
    -2.3513387162376693 + _t134_x1_t_,
    -2.6499171840170734 + _t134_x1ˍt_t_,
    _t134_x2ˍt_t_ + _t134_x2_t_*_tpc_ - _t134_x1_t_*_t134_x2_t_*_tpd_,
    _t134_x1ˍt_t_ - _t134_x1_t_*_tpa_ + _t134_x1_t_*_t134_x2_t_*_tpb_
]

