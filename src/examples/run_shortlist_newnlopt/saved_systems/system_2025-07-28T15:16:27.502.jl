# Polynomial system saved on 2025-07-28T15:16:27.502
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:27.502
# num_equations: 3

# Variables
varlist_str = """
_tpb_
_t167_x1_t_
_t167_x1ˍt_t_
"""
@variables _tpb_ _t167_x1_t_ _t167_x1ˍt_t_
varlist = [_tpb__t167_x1_t__t167_x1ˍt_t_]

# Polynomial System
poly_system = [
    -14.660358941326226 + _t167_x1_t_,
    -17.592430729570154 + _t167_x1ˍt_t_,
    _t167_x1ˍt_t_ + _t167_x1_t_*(-0.8287834283813679 - _tpb_)
]

