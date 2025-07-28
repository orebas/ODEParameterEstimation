# Polynomial system saved on 2025-07-28T15:36:13.534
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:36:13.534
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t45_x1_t_
_t45_x2_t_
_t45_x1ˍt_t_
_t45_x2ˍt_t_
_t112_x1_t_
_t112_x2_t_
_t112_x1ˍt_t_
_t112_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t45_x1_t_ _t45_x2_t_ _t45_x1ˍt_t_ _t45_x2ˍt_t_ _t112_x1_t_ _t112_x2_t_ _t112_x1ˍt_t_ _t112_x2ˍt_t_
varlist = [_tpa__tpb__t45_x1_t__t45_x2_t__t45_x1ˍt_t__t45_x2ˍt_t__t112_x1_t__t112_x2_t__t112_x1ˍt_t__t112_x2ˍt_t_]

# Polynomial System
poly_system = [
    0.6475581781146404 + 3.0_t45_x1_t_ - 0.25_t45_x2_t_,
    -1.2012502340974431 + 2.0_t45_x1_t_ + 0.5_t45_x2_t_,
    1.9642401243966612 + 2.0_t45_x1ˍt_t_ + 0.5_t45_x2ˍt_t_,
    _t45_x1ˍt_t_ + _t45_x2_t_*_tpa_,
    _t45_x2ˍt_t_ - _t45_x1_t_*_tpb_,
    4.593643503110982 + 3.0_t112_x1_t_ - 0.25_t112_x2_t_,
    2.11826142251257 + 2.0_t112_x1_t_ + 0.5_t112_x2_t_,
    1.6982785075839124 + 2.0_t112_x1ˍt_t_ + 0.5_t112_x2ˍt_t_,
    _t112_x1ˍt_t_ + _t112_x2_t_*_tpa_,
    _t112_x2ˍt_t_ - _t112_x1_t_*_tpb_
]

