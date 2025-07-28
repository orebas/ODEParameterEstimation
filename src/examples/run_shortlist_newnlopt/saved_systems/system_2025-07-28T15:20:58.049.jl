# Polynomial system saved on 2025-07-28T15:20:58.050
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:58.049
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t56_x1_t_
_t56_x2_t_
_t56_x2ˍt_t_
_t56_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t56_x1_t_ _t56_x2_t_ _t56_x2ˍt_t_ _t56_x1ˍt_t_
varlist = [_tpa__tpb__t56_x1_t__t56_x2_t__t56_x2ˍt_t__t56_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.7791443367256848 + _t56_x2_t_,
    -0.13810267800026843 + _t56_x2ˍt_t_,
    -0.17262837737528558 + _t56_x1_t_,
    0.31165773330584856 + _t56_x1ˍt_t_,
    _t56_x2ˍt_t_ - _t56_x1_t_*_tpb_,
    _t56_x1ˍt_t_ + _t56_x2_t_*_tpa_
]

