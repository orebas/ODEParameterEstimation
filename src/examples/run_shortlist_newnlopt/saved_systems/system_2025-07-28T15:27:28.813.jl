# Polynomial system saved on 2025-07-28T15:27:28.813
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:27:28.813
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t445_x1_t_
_t445_x2_t_
_t445_x2ˍt_t_
_t445_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t445_x1_t_ _t445_x2_t_ _t445_x2ˍt_t_ _t445_x1ˍt_t_
varlist = [_tpa__tpb__t445_x1_t__t445_x2_t__t445_x2ˍt_t__t445_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.5182281983124069 + _t445_x2_t_,
    0.8552424128998779 + _t445_x2ˍt_t_,
    0.8552423780096094 + _t445_x1_t_,
    0.5182281936095928 + _t445_x1ˍt_t_,
    -_t445_x1_t_ + _t445_x2ˍt_t_*_tpb_,
    _t445_x1ˍt_t_ + _t445_x2_t_*_tpa_
]

