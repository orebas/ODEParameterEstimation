# Polynomial system saved on 2025-07-28T15:27:55.607
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:27:55.607
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t167_x1_t_
_t167_x2_t_
_t167_x2ˍt_t_
_t167_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t167_x1_t_ _t167_x2_t_ _t167_x2ˍt_t_ _t167_x1ˍt_t_
varlist = [_tpa__tpb__t167_x1_t__t167_x2_t__t167_x2ˍt_t__t167_x1ˍt_t_]

# Polynomial System
poly_system = [
    0.17746241549605163 + _t167_x2_t_,
    0.9841275916173012 + _t167_x2ˍt_t_,
    0.98412757984578 + _t167_x1_t_,
    -0.17746244194825114 + _t167_x1ˍt_t_,
    -_t167_x1_t_ + _t167_x2ˍt_t_*_tpb_,
    _t167_x1ˍt_t_ + _t167_x2_t_*_tpa_
]

