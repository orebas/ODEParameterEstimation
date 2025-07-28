# Polynomial system saved on 2025-07-28T15:18:10.024
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:18:10.022
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t111_x1_t_
_t111_x2_t_
_t111_x1ˍt_t_
_t111_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t111_x1_t_ _t111_x2_t_ _t111_x1ˍt_t_ _t111_x2ˍt_t_
varlist = [_tpa__tpb__t111_x1_t__t111_x2_t__t111_x1ˍt_t__t111_x2ˍt_t_]

# Polynomial System
poly_system = [
    0.6475581966004509 + 3.0_t111_x1_t_ - 0.25_t111_x2_t_,
    2.9369735923626443 + 3.0_t111_x1ˍt_t_ - 0.25_t111_x2ˍt_t_,
    -1.2012502280952484 + 2.0_t111_x1_t_ + 0.5_t111_x2_t_,
    1.9642401392500286 + 2.0_t111_x1ˍt_t_ + 0.5_t111_x2ˍt_t_,
    _t111_x1ˍt_t_ + _t111_x2_t_*_tpa_,
    _t111_x2ˍt_t_ - _t111_x1_t_*_tpb_
]

