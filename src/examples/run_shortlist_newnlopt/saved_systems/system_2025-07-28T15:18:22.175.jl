# Polynomial system saved on 2025-07-28T15:18:22.175
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:18:22.175
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t111_x1_t_
_t111_x2_t_
_t111_x1ˍt_t_
_t111_x2ˍt_t_
_t278_x1_t_
_t278_x2_t_
_t278_x1ˍt_t_
_t278_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t111_x1_t_ _t111_x2_t_ _t111_x1ˍt_t_ _t111_x2ˍt_t_ _t278_x1_t_ _t278_x2_t_ _t278_x1ˍt_t_ _t278_x2ˍt_t_
varlist = [_tpa__tpb__t111_x1_t__t111_x2_t__t111_x1ˍt_t__t111_x2ˍt_t__t278_x1_t__t278_x2_t__t278_x1ˍt_t__t278_x2ˍt_t_]

# Polynomial System
poly_system = [
    0.647558151055319 + 3.0_t111_x1_t_ - 0.25_t111_x2_t_,
    -1.2012502089407184 + 2.0_t111_x1_t_ + 0.5_t111_x2_t_,
    1.9642401502784845 + 2.0_t111_x1ˍt_t_ + 0.5_t111_x2ˍt_t_,
    _t111_x1ˍt_t_ + _t111_x2_t_*_tpa_,
    _t111_x2ˍt_t_ - _t111_x1_t_*_tpb_,
    4.5865409206673515 + 3.0_t278_x1_t_ - 0.25_t278_x2_t_,
    2.109761489489262 + 2.0_t278_x1_t_ + 0.5_t278_x2_t_,
    1.701660979615889 + 2.0_t278_x1ˍt_t_ + 0.5_t278_x2ˍt_t_,
    _t278_x1ˍt_t_ + _t278_x2_t_*_tpa_,
    _t278_x2ˍt_t_ - _t278_x1_t_*_tpb_
]

