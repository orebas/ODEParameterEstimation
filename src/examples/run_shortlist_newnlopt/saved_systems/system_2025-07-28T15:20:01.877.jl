# Polynomial system saved on 2025-07-28T15:20:01.878
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:01.877
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpc_
_t111_x1_t_
_t111_x2_t_
_t111_x2ˍt_t_
_t111_x1ˍt_t_
"""
@variables _tpa_ _tpc_ _t111_x1_t_ _t111_x2_t_ _t111_x2ˍt_t_ _t111_x1ˍt_t_
varlist = [_tpa__tpc__t111_x1_t__t111_x2_t__t111_x2ˍt_t__t111_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.0416586470346925 + _t111_x2_t_,
    -0.895834135296397 + _t111_x2ˍt_t_,
    -1.7916682705930613 + _t111_x1_t_,
    0.17916682705928189 + _t111_x1ˍt_t_,
    _t111_x2ˍt_t_ - _t111_x1_t_*(0.25748185557408443 + _tpc_),
    _t111_x1ˍt_t_ + _t111_x1_t_*_tpa_
]

