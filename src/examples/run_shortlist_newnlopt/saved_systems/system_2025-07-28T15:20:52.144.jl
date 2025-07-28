# Polynomial system saved on 2025-07-28T15:20:52.144
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:52.144
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t334_x1_t_
_t334_x2_t_
_t334_x2ˍt_t_
_t334_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t334_x1_t_ _t334_x2_t_ _t334_x2ˍt_t_ _t334_x1ˍt_t_
varlist = [_tpa__tpb__t334_x1_t__t334_x2_t__t334_x2ˍt_t__t334_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.2427233862380742 + _t334_x2_t_,
    0.44099972164090673 + _t334_x2ˍt_t_,
    0.5512496520511931 + _t334_x1_t_,
    0.0970893544952034 + _t334_x1ˍt_t_,
    _t334_x2ˍt_t_ - _t334_x1_t_*_tpb_,
    _t334_x1ˍt_t_ + _t334_x2_t_*_tpa_
]

