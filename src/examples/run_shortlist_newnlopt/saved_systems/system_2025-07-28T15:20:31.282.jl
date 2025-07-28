# Polynomial system saved on 2025-07-28T15:20:31.283
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:31.282
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t278_x1_t_
_t278_x2_t_
_t278_x2ˍt_t_
_t278_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t278_x1_t_ _t278_x2_t_ _t278_x2ˍt_t_ _t278_x1ˍt_t_
varlist = [_tpa__tpb__t278_x1_t__t278_x2_t__t278_x2ˍt_t__t278_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.473496038727961 + _t278_x2_t_,
    0.3762843556181009 + _t278_x2ˍt_t_,
    0.47035545675737533 + _t278_x1_t_,
    0.18939841319027087 + _t278_x1ˍt_t_,
    _t278_x2ˍt_t_ - _t278_x1_t_*_tpb_,
    _t278_x1ˍt_t_ + _t278_x2_t_*_tpa_
]

