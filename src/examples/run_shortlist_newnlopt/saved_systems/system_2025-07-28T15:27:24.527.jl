# Polynomial system saved on 2025-07-28T15:27:24.528
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:27:24.528
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t334_x1_t_
_t334_x2_t_
_t334_x2ˍt_t_
_t334_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t334_x1_t_ _t334_x2_t_ _t334_x2ˍt_t_ _t334_x1ˍt_t_
varlist = [_tpa__tpb__t334_x1_t__t334_x2_t__t334_x2ˍt_t__t334_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.3679605038606342 + _t334_x2_t_,
    -0.9298414413403296 + _t334_x2ˍt_t_,
    -0.9298414358723057 + _t334_x1_t_,
    0.36796052120074335 + _t334_x1ˍt_t_,
    -_t334_x1_t_ + _t334_x2ˍt_t_*_tpb_,
    _t334_x1ˍt_t_ + _t334_x2_t_*_tpa_
]

