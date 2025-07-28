# Polynomial system saved on 2025-07-28T15:45:12.520
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:45:12.520
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
    4.593643520277764 + 3.0_t112_x1_t_ - 0.25_t112_x2_t_,
    1.4168629431456583 + 3.0_t112_x1ˍt_t_ - 0.25_t112_x2ˍt_t_,
    2.1182614333679726 + 2.0_t112_x1_t_ + 0.5_t112_x2_t_,
    1.6982785434555363 + 2.0_t112_x1ˍt_t_ + 0.5_t112_x2ˍt_t_,
    _t112_x1ˍt_t_ + _t112_x2_t_*_tpa_,
    _t112_x2ˍt_t_ - _t112_x1_t_*_tpb_
]

