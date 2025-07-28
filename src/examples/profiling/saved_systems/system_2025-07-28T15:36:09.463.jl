# Polynomial system saved on 2025-07-28T15:36:09.464
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:36:09.463
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t201_x1_t_
_t201_x2_t_
_t201_x1ˍt_t_
_t201_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t201_x1_t_ _t201_x2_t_ _t201_x1ˍt_t_ _t201_x2ˍt_t_
varlist = [_tpa__tpb__t201_x1_t__t201_x2_t__t201_x1ˍt_t__t201_x2ˍt_t_]

# Polynomial System
poly_system = [
    3.794365341226187 + 3.0_t201_x1_t_ - 0.25_t201_x2_t_,
    -2.03786438161516 + 3.0_t201_x1ˍt_t_ - 0.25_t201_x2ˍt_t_,
    3.507608228546585 + 2.0_t201_x1_t_ + 0.5_t201_x2_t_,
    -0.6188220725050698 + 2.0_t201_x1ˍt_t_ + 0.5_t201_x2ˍt_t_,
    _t201_x1ˍt_t_ + _t201_x2_t_*_tpa_,
    _t201_x2ˍt_t_ - _t201_x1_t_*_tpb_
]

