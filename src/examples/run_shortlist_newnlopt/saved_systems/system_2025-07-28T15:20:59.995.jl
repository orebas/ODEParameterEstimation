# Polynomial system saved on 2025-07-28T15:20:59.995
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:59.995
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t167_x1_t_
_t167_x2_t_
_t167_x2ˍt_t_
_t167_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t167_x1_t_ _t167_x2_t_ _t167_x2ˍt_t_ _t167_x1ˍt_t_
varlist = [_tpa__tpb__t167_x1_t__t167_x2_t__t167_x2ˍt_t__t167_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.7739451286473962 + _t167_x2_t_,
    0.14716078747271102 + _t167_x2ˍt_t_,
    0.1839510040392963 + _t167_x1_t_,
    0.30957806190796605 + _t167_x1ˍt_t_,
    _t167_x2ˍt_t_ - _t167_x1_t_*_tpb_,
    _t167_x1ˍt_t_ + _t167_x2_t_*_tpa_
]

