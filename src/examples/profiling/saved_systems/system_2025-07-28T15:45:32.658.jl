# Polynomial system saved on 2025-07-28T15:45:32.658
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:45:32.658
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t156_x1_t_
_t156_x2_t_
_t156_x1ˍt_t_
_t156_x2ˍt_t_
_t201_x1_t_
_t201_x2_t_
_t201_x1ˍt_t_
_t201_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t156_x1_t_ _t156_x2_t_ _t156_x1ˍt_t_ _t156_x2ˍt_t_ _t201_x1_t_ _t201_x2_t_ _t201_x1ˍt_t_ _t201_x2ˍt_t_
varlist = [_tpa__tpb__t156_x1_t__t156_x2_t__t156_x1ˍt_t__t156_x2ˍt_t__t201_x1_t__t201_x2_t__t201_x1ˍt_t__t201_x2ˍt_t_]

# Polynomial System
poly_system = [
    5.192542201234199 + 3.0_t156_x1_t_ - 0.25_t156_x2_t_,
    3.4710926879095276 + 2.0_t156_x1_t_ + 0.5_t156_x2_t_,
    0.6815315856212039 + 2.0_t156_x1ˍt_t_ + 0.5_t156_x2ˍt_t_,
    _t156_x1ˍt_t_ + _t156_x2_t_*_tpa_,
    _t156_x2ˍt_t_ - _t156_x1_t_*_tpb_,
    3.7943652979642284 + 3.0_t201_x1_t_ - 0.25_t201_x2_t_,
    3.5076082869156586 + 2.0_t201_x1_t_ + 0.5_t201_x2_t_,
    -0.6188204775937025 + 2.0_t201_x1ˍt_t_ + 0.5_t201_x2ˍt_t_,
    _t201_x1ˍt_t_ + _t201_x2_t_*_tpa_,
    _t201_x2ˍt_t_ - _t201_x1_t_*_tpb_
]

