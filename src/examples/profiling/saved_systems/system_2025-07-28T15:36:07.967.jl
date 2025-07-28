# Polynomial system saved on 2025-07-28T15:36:07.967
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:36:07.967
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t156_x1_t_
_t156_x2_t_
_t156_x1ˍt_t_
_t156_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t156_x1_t_ _t156_x2_t_ _t156_x1ˍt_t_ _t156_x2ˍt_t_
varlist = [_tpa__tpb__t156_x1_t__t156_x2_t__t156_x1ˍt_t__t156_x2ˍt_t_]

# Polynomial System
poly_system = [
    5.1925425960836264 + 3.0_t156_x1_t_ - 0.25_t156_x2_t_,
    -0.36332055240700006 + 3.0_t156_x1ˍt_t_ - 0.25_t156_x2ˍt_t_,
    3.471092610477767 + 2.0_t156_x1_t_ + 0.5_t156_x2_t_,
    0.6815314940912337 + 2.0_t156_x1ˍt_t_ + 0.5_t156_x2ˍt_t_,
    _t156_x1ˍt_t_ + _t156_x2_t_*_tpa_,
    _t156_x2ˍt_t_ - _t156_x1_t_*_tpb_
]

