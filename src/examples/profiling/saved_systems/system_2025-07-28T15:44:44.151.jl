# Polynomial system saved on 2025-07-28T15:44:44.151
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:44:44.151
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t156_x1_t_
_t156_x2_t_
_t156_x2ˍt_t_
_t156_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t156_x1_t_ _t156_x2_t_ _t156_x2ˍt_t_ _t156_x1ˍt_t_
varlist = [_tpa__tpb__t156_x1_t__t156_x2_t__t156_x2ˍt_t__t156_x1ˍt_t_]

# Polynomial System
poly_system = [
    0.0052762938690969485 + _t156_x2_t_,
    0.4618706734065831 + _t156_x2ˍt_t_,
    0.5773383653692595 + _t156_x1_t_,
    -0.002110489770618339 + _t156_x1ˍt_t_,
    _t156_x2ˍt_t_ - _t156_x1_t_*_tpb_,
    _t156_x1ˍt_t_ + _t156_x2_t_*_tpa_
]

