# Polynomial system saved on 2025-07-28T15:35:51.549
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:35:51.548
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
    -0.8164739519374832 + _t45_x2_t_,
    0.003455435768701876 + _t45_x2ˍt_t_,
    0.004319328741761552 + _t45_x1_t_,
    0.32658956972484915 + _t45_x1ˍt_t_,
    _t45_x2ˍt_t_ - _t45_x1_t_*_tpb_,
    _t45_x1ˍt_t_ + _t45_x2_t_*_tpa_
]

