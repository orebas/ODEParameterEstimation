# Polynomial system saved on 2025-07-28T15:16:26.633
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:26.633
# num_equations: 3

# Variables
varlist_str = """
_tpb_
_t445_x1_t_
_t445_x1ˍt_t_
"""
@variables _tpb_ _t445_x1_t_ _t445_x1ˍt_t_
varlist = [_tpb__t445_x1_t__t445_x1ˍt_t_]

# Polynomial System
poly_system = [
    -412.0510254774742 + _t445_x1_t_,
    -494.46128770667747 + _t445_x1ˍt_t_,
    _t445_x1ˍt_t_ + _t445_x1_t_*(-0.12517116098470515 - _tpb_)
]

