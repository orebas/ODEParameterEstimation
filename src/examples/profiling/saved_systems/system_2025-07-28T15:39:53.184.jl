# Polynomial system saved on 2025-07-28T15:39:53.184
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:39:53.184
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t156_x1_t_
_t156_x2_t_
_t156_x2ˍt_t_
_t156_x1ˍt_t_
_t201_x1_t_
_t201_x2_t_
_t201_x2ˍt_t_
_t201_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t156_x1_t_ _t156_x2_t_ _t156_x2ˍt_t_ _t156_x1ˍt_t_ _t201_x1_t_ _t201_x2_t_ _t201_x2ˍt_t_ _t201_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t156_x1_t__t156_x2_t__t156_x2ˍt_t__t156_x1ˍt_t__t201_x1_t__t201_x2_t__t201_x2ˍt_t__t201_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.686849989859515 + _t156_x2_t_,
    -3.371104963522571 + _t156_x2ˍt_t_,
    -4.649081148587565 + _t156_x1_t_,
    12.636993179082294 + _t156_x1ˍt_t_,
    _t156_x2ˍt_t_ + _t156_x2_t_*_tpc_ - _t156_x1_t_*_t156_x2_t_*_tpd_,
    _t156_x1ˍt_t_ - _t156_x1_t_*_tpa_ + _t156_x1_t_*_t156_x2_t_*_tpb_,
    -4.804236544597398 + _t201_x2_t_,
    0.8942842469797223 + _t201_x2ˍt_t_,
    -3.5181615758968148 + _t201_x1_t_,
    9.928165368198776 + _t201_x1ˍt_t_,
    _t201_x2ˍt_t_ + _t201_x2_t_*_tpc_ - _t201_x1_t_*_t201_x2_t_*_tpd_,
    _t201_x1ˍt_t_ - _t201_x1_t_*_tpa_ + _t201_x1_t_*_t201_x2_t_*_tpb_
]

