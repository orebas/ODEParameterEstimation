# Polynomial system saved on 2025-07-28T15:16:17.765
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:17.764
# num_equations: 3

# Variables
varlist_str = """
_tpb_
_t111_x1_t_
_t111_x1ˍt_t_
"""
@variables _tpb_ _t111_x1_t_ _t111_x1ˍt_t_
varlist = [_tpb__t111_x1_t__t111_x1ˍt_t_]

# Polynomial System
poly_system = [
    -7.486849182908458 + _t111_x1_t_,
    -8.98423002805269 + _t111_x1ˍt_t_,
    _t111_x1ˍt_t_ - _t111_x1_t_*(0.3703923783894607 + _tpb_)
]

