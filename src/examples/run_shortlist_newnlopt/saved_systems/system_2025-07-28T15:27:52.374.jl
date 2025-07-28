# Polynomial system saved on 2025-07-28T15:27:52.374
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:27:52.374
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t56_x1_t_
_t56_x2_t_
_t56_x2ˍt_t_
_t56_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t56_x1_t_ _t56_x2_t_ _t56_x2ˍt_t_ _t56_x1ˍt_t_
varlist = [_tpa__tpb__t56_x1_t__t56_x2_t__t56_x2ˍt_t__t56_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.8912073635068547 + _t56_x2_t_,
    -0.45359615592158337 + _t56_x2ˍt_t_,
    -0.45359611890798157 + _t56_x1_t_,
    0.891207378834832 + _t56_x1ˍt_t_,
    -_t56_x1_t_ + _t56_x2ˍt_t_*_tpb_,
    _t56_x1ˍt_t_ + _t56_x2_t_*_tpa_
]

