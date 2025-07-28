# Polynomial system saved on 2025-07-28T15:17:59.199
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:17:59.199
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t167_x1_t_
_t167_x2_t_
_t167_x1ˍt_t_
_t167_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t167_x1_t_ _t167_x2_t_ _t167_x1ˍt_t_ _t167_x2ˍt_t_
varlist = [_tpa__tpb__t167_x1_t__t167_x2_t__t167_x1ˍt_t__t167_x2ˍt_t_]

# Polynomial System
poly_system = [
    2.232671751589753 + 3.0_t167_x1_t_ - 0.25_t167_x2_t_,
    2.6767249062022715 + 3.0_t167_x1ˍt_t_ - 0.25_t167_x2ˍt_t_,
    -0.0598095923838573 + 2.0_t167_x1_t_ + 0.5_t167_x2_t_,
    2.0781855974492394 + 2.0_t167_x1ˍt_t_ + 0.5_t167_x2ˍt_t_,
    _t167_x1ˍt_t_ + _t167_x2_t_*_tpa_,
    _t167_x2ˍt_t_ - _t167_x1_t_*_tpb_
]

