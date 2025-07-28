# Polynomial system saved on 2025-07-28T15:16:27.669
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:27.669
# num_equations: 3

# Variables
varlist_str = """
_tpb_
_t390_x1_t_
_t390_x1ˍt_t_
"""
@variables _tpb_ _t390_x1_t_ _t390_x1ˍt_t_
varlist = [_tpb__t390_x1_t__t390_x1ˍt_t_]

# Polynomial System
poly_system = [
    -212.96912040175724 + _t390_x1_t_,
    -255.5629444820779 + _t390_x1ˍt_t_,
    _t390_x1ˍt_t_ + _t390_x1_t_*(-0.8140548293523846 - _tpb_)
]

