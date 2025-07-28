# Polynomial system saved on 2025-07-28T15:27:46.893
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:27:46.892
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t390_x1_t_
_t390_x2_t_
_t390_x2ˍt_t_
_t390_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t390_x1_t_ _t390_x2_t_ _t390_x2ˍt_t_ _t390_x1ˍt_t_
varlist = [_tpa__tpb__t390_x1_t__t390_x2_t__t390_x2ˍt_t__t390_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.9972646068902717 + _t390_x2_t_,
    -0.07391416538118989 + _t390_x2ˍt_t_,
    -0.0739141653812287 + _t390_x1_t_,
    0.9972646068902234 + _t390_x1ˍt_t_,
    -_t390_x1_t_ + _t390_x2ˍt_t_*_tpb_,
    _t390_x1ˍt_t_ + _t390_x2_t_*_tpa_
]

