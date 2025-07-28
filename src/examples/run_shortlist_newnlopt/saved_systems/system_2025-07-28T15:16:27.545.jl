# Polynomial system saved on 2025-07-28T15:16:27.545
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:27.545
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
    -28.7071775560664 + _t223_x1_t_,
    -34.44861306731539 + _t223_x1ˍt_t_,
    _t223_x1ˍt_t_ - _t223_x1_t_*(0.4341262855801449 + _tpb_)
]

