# Polynomial system saved on 2025-07-28T15:36:09.577
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:36:09.576
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t45_x1_t_
_t45_x2_t_
_t45_x1ˍt_t_
_t45_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t45_x1_t_ _t45_x2_t_ _t45_x1ˍt_t_ _t45_x2ˍt_t_
varlist = [_tpa__tpb__t45_x1_t__t45_x2_t__t45_x1ˍt_t__t45_x2ˍt_t_]

# Polynomial System
poly_system = [
    0.6475581966003233 + 3.0_t45_x1_t_ - 0.25_t45_x2_t_,
    2.9369735923637563 + 3.0_t45_x1ˍt_t_ - 0.25_t45_x2ˍt_t_,
    -1.2012502280952264 + 2.0_t45_x1_t_ + 0.5_t45_x2_t_,
    1.9642401392500322 + 2.0_t45_x1ˍt_t_ + 0.5_t45_x2ˍt_t_,
    _t45_x1ˍt_t_ + _t45_x2_t_*_tpa_,
    _t45_x2ˍt_t_ - _t45_x1_t_*_tpb_
]

