# Polynomial system saved on 2025-07-28T15:08:16.031
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:08:16.031
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
    -3.9567442908339716 + _t334_x2_t_,
    -0.1639618730255255 + _t334_x2ˍt_t_,
    -4.0015987194055285 + _t334_x3_t_,
    -0.0004801918421354317 + _t334_x3ˍt_t_,
    -0.8198093268437099 + _t334_x1_t_,
    0.3956744186896603 + _t334_x1ˍt_t_,
    _t334_x2ˍt_t_ - _t334_x1_t_*_tpb_,
    _t334_x3ˍt_t_ - _t334_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t334_x1ˍt_t_ + _t334_x2_t_*_tpa_
]

