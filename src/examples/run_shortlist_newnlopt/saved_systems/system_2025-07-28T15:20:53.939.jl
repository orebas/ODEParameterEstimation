# Polynomial system saved on 2025-07-28T15:20:53.940
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:53.939
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
    0.012204028563252572 + _t390_x2_t_,
    0.46182873420764115 + _t390_x2ˍt_t_,
    0.5772859177594873 + _t390_x1_t_,
    -0.0048816114252634435 + _t390_x1ˍt_t_,
    _t390_x2ˍt_t_ - _t390_x1_t_*_tpb_,
    _t390_x1ˍt_t_ + _t390_x2_t_*_tpa_
]

