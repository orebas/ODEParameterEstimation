# Polynomial system saved on 2025-07-28T15:07:55.344
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:07:55.343
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpbeta_
_t334_x1_t_
_t334_x2_t_
_t334_x3_t_
_t334_x2ˍt_t_
_t334_x3ˍt_t_
_t334_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpbeta_ _t334_x1_t_ _t334_x2_t_ _t334_x3_t_ _t334_x2ˍt_t_ _t334_x3ˍt_t_ _t334_x1ˍt_t_
varlist = [_tpa__tpb__tpbeta__t334_x1_t__t334_x2_t__t334_x3_t__t334_x2ˍt_t__t334_x3ˍt_t__t334_x1ˍt_t_]

# Polynomial System
poly_system = [
    -3.956744279628928 + _t334_x2_t_,
    -0.1639618894187549 + _t334_x2ˍt_t_,
    -4.001598719401609 + _t334_x3_t_,
    -0.000480191851805503 + _t334_x3ˍt_t_,
    -0.8198093423226491 + _t334_x1_t_,
    0.3956744172363328 + _t334_x1ˍt_t_,
    _t334_x2ˍt_t_ - _t334_x1_t_*_tpb_,
    _t334_x3ˍt_t_ - _t334_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t334_x1ˍt_t_ + _t334_x2_t_*_tpa_
]

