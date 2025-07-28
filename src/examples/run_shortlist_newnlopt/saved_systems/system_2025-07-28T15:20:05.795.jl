# Polynomial system saved on 2025-07-28T15:20:05.796
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:05.795
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpc_
_t111_x1_t_
_t111_x2_t_
_t111_x2ˍt_t_
_t111_x1ˍt_t_
"""
@variables _tpa_ _tpc_ _t111_x1_t_ _t111_x2_t_ _t111_x2ˍt_t_ _t111_x1ˍt_t_
varlist = [_tpa__tpc__t111_x1_t__t111_x2_t__t111_x2ˍt_t__t111_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.041658641478182 + _t111_x2_t_,
    -0.8958342048251369 + _t111_x2ˍt_t_,
    -1.7916682707153941 + _t111_x1_t_,
    0.17916683663863453 + _t111_x1ˍt_t_,
    _t111_x2ˍt_t_ - _t111_x1_t_*(0.7065557210498287 + _tpc_),
    _t111_x1ˍt_t_ + _t111_x1_t_*_tpa_
]

