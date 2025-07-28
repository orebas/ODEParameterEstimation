# Polynomial system saved on 2025-07-28T15:35:53.751
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:35:53.751
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t179_x1_t_
_t179_x2_t_
_t179_x2ˍt_t_
_t179_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t179_x1_t_ _t179_x2_t_ _t179_x2ˍt_t_ _t179_x1ˍt_t_
varlist = [_tpa__tpb__t179_x1_t__t179_x2_t__t179_x2ˍt_t__t179_x1ˍt_t_]

# Polynomial System
poly_system = [
    0.2659169518627178 + _t179_x2_t_,
    0.4366985974884509 + _t179_x2ˍt_t_,
    0.5458731528622107 + _t179_x1_t_,
    -0.10636684770472941 + _t179_x1ˍt_t_,
    _t179_x2ˍt_t_ - _t179_x1_t_*_tpb_,
    _t179_x1ˍt_t_ + _t179_x2_t_*_tpa_
]

