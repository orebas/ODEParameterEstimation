# Polynomial system saved on 2025-07-28T15:16:34.105
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:34.105
# num_equations: 3

# Variables
varlist_str = """
_tpb_
_t223_x1_t_
_t223_x1ˍt_t_
"""
@variables _tpb_ _t223_x1_t_ _t223_x1ˍt_t_
varlist = [_tpb__t223_x1_t__t223_x1ˍt_t_]

# Polynomial System
poly_system = [
    -28.707176893735706 + _t223_x1_t_,
    -34.448606472721224 + _t223_x1ˍt_t_,
    _t223_x1ˍt_t_ - _t223_x1_t_*(0.35581141429056584 + _tpb_)
]

