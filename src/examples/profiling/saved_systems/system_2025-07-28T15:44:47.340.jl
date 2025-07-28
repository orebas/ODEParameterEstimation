# Polynomial system saved on 2025-07-28T15:44:47.341
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:44:47.340
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t45_x1_t_
_t45_x2_t_
_t45_x2ˍt_t_
_t45_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t45_x1_t_ _t45_x2_t_ _t45_x2ˍt_t_ _t45_x1ˍt_t_
varlist = [_tpa__tpb__t45_x1_t__t45_x2_t__t45_x2ˍt_t__t45_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.8164739351575369 + _t45_x2_t_,
    0.0034554633086543163 + _t45_x2ˍt_t_,
    0.0043193291358621586 + _t45_x1_t_,
    0.32658957406298683 + _t45_x1ˍt_t_,
    _t45_x2ˍt_t_ - _t45_x1_t_*_tpb_,
    _t45_x1ˍt_t_ + _t45_x2_t_*_tpa_
]

