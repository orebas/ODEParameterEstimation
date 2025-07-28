# Polynomial system saved on 2025-07-28T15:19:49.553
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:19:49.553
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpc_
_t167_x1_t_
_t167_x2_t_
_t167_x2ˍt_t_
_t167_x1ˍt_t_
"""
@variables _tpa_ _tpc_ _t167_x1_t_ _t167_x2_t_ _t167_x2ˍt_t_ _t167_x1ˍt_t_
varlist = [_tpa__tpc__t167_x1_t__t167_x2_t__t167_x2ˍt_t__t167_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.5295376542624 + _t167_x2_t_,
    -0.847046189880324 + _t167_x2ˍt_t_,
    -1.6940924676146798 + _t167_x1_t_,
    0.16940923767164554 + _t167_x1ˍt_t_,
    _t167_x2ˍt_t_ + _t167_x1_t_*(-0.19283128856201337 - _tpc_),
    _t167_x1ˍt_t_ + _t167_x1_t_*_tpa_
]

