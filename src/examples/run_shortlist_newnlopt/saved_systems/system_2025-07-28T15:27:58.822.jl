# Polynomial system saved on 2025-07-28T15:27:58.822
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:27:58.822
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
    0.6766367380100524 + _t278_x2_t_,
    -0.7363169976725992 + _t278_x2ˍt_t_,
    -0.7363170039358284 + _t278_x1_t_,
    -0.6766367285332241 + _t278_x1ˍt_t_,
    -_t278_x1_t_ + _t278_x2ˍt_t_*_tpb_,
    _t278_x1ˍt_t_ + _t278_x2_t_*_tpa_
]

