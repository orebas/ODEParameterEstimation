# Polynomial system saved on 2025-07-28T15:21:05.386
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:21:05.386
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
    0.012204028908213704 + _t390_x2_t_,
    0.461828726170039 + _t390_x2ˍt_t_,
    0.577285928274264 + _t390_x1_t_,
    -0.004881607226959748 + _t390_x1ˍt_t_,
    _t390_x2ˍt_t_ - _t390_x1_t_*_tpb_,
    _t390_x1ˍt_t_ + _t390_x2_t_*_tpa_
]

