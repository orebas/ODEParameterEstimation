# Polynomial system saved on 2025-07-28T15:08:02.151
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:08:02.151
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpbeta_
_t223_x1_t_
_t223_x2_t_
_t223_x3_t_
_t223_x2ˍt_t_
_t223_x3ˍt_t_
_t223_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpbeta_ _t223_x1_t_ _t223_x2_t_ _t223_x3_t_ _t223_x2ˍt_t_ _t223_x3ˍt_t_ _t223_x1ˍt_t_
varlist = [_tpa__tpb__tpbeta__t223_x1_t__t223_x2_t__t223_x3_t__t223_x2ˍt_t__t223_x3ˍt_t__t223_x1ˍt_t_]

# Polynomial System
poly_system = [
    -3.7268421364421536 + _t223_x2_t_,
    -0.2494252469193956 + _t223_x2ˍt_t_,
    -4.001065741950528 + _t223_x3_t_,
    -0.00048012788903561976 + _t223_x3ˍt_t_,
    -1.2471262345968475 + _t223_x1_t_,
    0.3726842136442521 + _t223_x1ˍt_t_,
    _t223_x2ˍt_t_ - _t223_x1_t_*_tpb_,
    _t223_x3ˍt_t_ - _t223_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t223_x1ˍt_t_ + _t223_x2_t_*_tpa_
]

