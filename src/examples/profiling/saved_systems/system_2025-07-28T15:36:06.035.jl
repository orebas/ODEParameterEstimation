# Polynomial system saved on 2025-07-28T15:36:06.036
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:36:06.035
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t45_x1_t_
_t45_x2_t_
_t45_x1ˍt_t_
_t45_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t45_x1_t_ _t45_x2_t_ _t45_x1ˍt_t_ _t45_x2ˍt_t_
varlist = [_tpa__tpb__t45_x1_t__t45_x2_t__t45_x1ˍt_t__t45_x2ˍt_t_]

# Polynomial System
poly_system = [
    0.6475582190803215 + 3.0_t45_x1_t_ - 0.25_t45_x2_t_,
    2.9369736041502317 + 3.0_t45_x1ˍt_t_ - 0.25_t45_x2ˍt_t_,
    -1.201250234402759 + 2.0_t45_x1_t_ + 0.5_t45_x2_t_,
    1.9642400665761899 + 2.0_t45_x1ˍt_t_ + 0.5_t45_x2ˍt_t_,
    _t45_x1ˍt_t_ + _t45_x2_t_*_tpa_,
    _t45_x2ˍt_t_ - _t45_x1_t_*_tpb_
]

