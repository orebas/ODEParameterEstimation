# Polynomial system saved on 2025-07-28T15:15:52.517
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:15:52.517
# num_equations: 3

# Variables
varlist_str = """
_tpb_
_t56_x1_t_
_t56_x1ˍt_t_
"""
@variables _tpb_ _t56_x1_t_ _t56_x1ˍt_t_
varlist = [_tpb__t56_x1_t__t56_x1ˍt_t_]

# Polynomial System
poly_system = [
    -3.869586251373619 + _t56_x1_t_,
    -4.64351102435369 + _t56_x1ˍt_t_,
    _t56_x1ˍt_t_ + _t56_x1_t_*(-0.1837430501479046 - _tpb_)
]

