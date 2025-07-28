# Polynomial system saved on 2025-07-28T15:16:20.342
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:20.342
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
    -28.707185349619536 + _t223_x1_t_,
    -34.44861670606611 + _t223_x1ˍt_t_,
    _t223_x1ˍt_t_ - _t223_x1_t_*(0.9500950009601539 + _tpb_)
]

