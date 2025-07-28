# Polynomial system saved on 2025-07-28T15:16:27.416
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:27.415
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
    -3.8695846688034057 + _t56_x1_t_,
    -4.643501602599429 + _t56_x1ˍt_t_,
    _t56_x1ˍt_t_ - _t56_x1_t_*(0.9034834239261703 + _tpb_)
]

