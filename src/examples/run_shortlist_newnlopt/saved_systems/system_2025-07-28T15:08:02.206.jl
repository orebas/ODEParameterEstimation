# Polynomial system saved on 2025-07-28T15:08:02.206
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:08:02.206
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpbeta_
_t278_x1_t_
_t278_x2_t_
_t278_x3_t_
_t278_x2ˍt_t_
_t278_x3ˍt_t_
_t278_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpbeta_ _t278_x1_t_ _t278_x2_t_ _t278_x3_t_ _t278_x2ˍt_t_ _t278_x3ˍt_t_ _t278_x1ˍt_t_
varlist = [_tpa__tpb__tpbeta__t278_x1_t__t278_x2_t__t278_x3_t__t278_x2ˍt_t__t278_x3ˍt_t__t278_x1ˍt_t_]

# Polynomial System
poly_system = [
    -3.8526197222144827 + _t278_x2_t_,
    -0.20771717675744128 + _t278_x2ˍt_t_,
    -4.001329821004009 + _t278_x3_t_,
    -0.00048015957852021174 + _t278_x3ˍt_t_,
    -1.0385858837871778 + _t278_x1_t_,
    0.3852619722214803 + _t278_x1ˍt_t_,
    _t278_x2ˍt_t_ - _t278_x1_t_*_tpb_,
    _t278_x3ˍt_t_ - _t278_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t278_x1ˍt_t_ + _t278_x2_t_*_tpa_
]

