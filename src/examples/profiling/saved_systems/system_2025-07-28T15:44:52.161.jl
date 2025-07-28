# Polynomial system saved on 2025-07-28T15:44:52.162
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:44:52.162
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t22_x1_t_
_t22_x2_t_
_t22_x2ˍt_t_
_t22_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t22_x1_t_ _t22_x2_t_ _t22_x2ˍt_t_ _t22_x1ˍt_t_
varlist = [_tpa__tpb__t22_x1_t__t22_x2_t__t22_x2ˍt_t__t22_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.7756139651550141 + _t22_x2_t_,
    -0.14432179541515266 + _t22_x2ˍt_t_,
    -0.18040228845033296 + _t22_x1_t_,
    0.3102455959999039 + _t22_x1ˍt_t_,
    _t22_x2ˍt_t_ - _t22_x1_t_*_tpb_,
    _t22_x1ˍt_t_ + _t22_x2_t_*_tpa_
]

