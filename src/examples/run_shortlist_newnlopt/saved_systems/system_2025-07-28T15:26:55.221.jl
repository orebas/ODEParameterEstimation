# Polynomial system saved on 2025-07-28T15:26:55.221
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:26:55.221
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
    -0.8912073521785164 + _t56_x2_t_,
    -0.45359614809119 + _t56_x2ˍt_t_,
    -0.4535961248903433 + _t56_x1_t_,
    0.8912073453583116 + _t56_x1ˍt_t_,
    -_t56_x1_t_ + _t56_x2ˍt_t_*_tpb_,
    _t56_x1ˍt_t_ + _t56_x2_t_*_tpa_
]

