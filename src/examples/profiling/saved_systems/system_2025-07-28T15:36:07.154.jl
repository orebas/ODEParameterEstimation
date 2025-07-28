# Polynomial system saved on 2025-07-28T15:36:07.155
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:36:07.154
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t112_x1_t_
_t112_x2_t_
_t112_x1ˍt_t_
_t112_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t112_x1_t_ _t112_x2_t_ _t112_x1ˍt_t_ _t112_x2ˍt_t_
varlist = [_tpa__tpb__t112_x1_t__t112_x2_t__t112_x1ˍt_t__t112_x2ˍt_t_]

# Polynomial System
poly_system = [
    4.593643516938628 + 3.0_t112_x1_t_ - 0.25_t112_x2_t_,
    1.4168629378438697 + 3.0_t112_x1ˍt_t_ - 0.25_t112_x2ˍt_t_,
    2.1182614051629267 + 2.0_t112_x1_t_ + 0.5_t112_x2_t_,
    1.69827852953276 + 2.0_t112_x1ˍt_t_ + 0.5_t112_x2ˍt_t_,
    _t112_x1ˍt_t_ + _t112_x2_t_*_tpa_,
    _t112_x2ˍt_t_ - _t112_x1_t_*_tpb_
]

