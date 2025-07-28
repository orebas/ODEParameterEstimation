# Polynomial system saved on 2025-07-28T15:26:31.162
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:26:31.162
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t111_x1_t_
_t111_x2_t_
_t111_x2ˍt_t_
_t111_x1ˍt_t_
_t278_x1_t_
_t278_x2_t_
_t278_x2ˍt_t_
_t278_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t111_x1_t_ _t111_x2_t_ _t111_x2ˍt_t_ _t111_x1ˍt_t_ _t278_x1_t_ _t278_x2_t_ _t278_x2ˍt_t_ _t278_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t111_x1_t__t111_x2_t__t111_x2ˍt_t__t111_x1ˍt_t__t278_x1_t__t278_x2_t__t278_x2ˍt_t__t278_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.4834263623382955 + _t111_x2_t_,
    0.6565436324736085 + _t111_x2ˍt_t_,
    -2.0523687464923315 + _t111_x1_t_,
    -2.185600819825821 + _t111_x1ˍt_t_,
    _t111_x2ˍt_t_ + _t111_x2_t_*_tpc_ - _t111_x1_t_*_t111_x2_t_*_tpd_,
    _t111_x1ˍt_t_ - _t111_x1_t_*_tpa_ + _t111_x1_t_*_t111_x2_t_*_tpb_,
    -4.5194080113398805 + _t278_x2_t_,
    -5.101088141507135 + _t278_x2ˍt_t_,
    -5.160883933664567 + _t278_x1_t_,
    13.250402829933346 + _t278_x1ˍt_t_,
    _t278_x2ˍt_t_ + _t278_x2_t_*_tpc_ - _t278_x1_t_*_t278_x2_t_*_tpd_,
    _t278_x1ˍt_t_ - _t278_x1_t_*_tpa_ + _t278_x1_t_*_t278_x2_t_*_tpb_
]

