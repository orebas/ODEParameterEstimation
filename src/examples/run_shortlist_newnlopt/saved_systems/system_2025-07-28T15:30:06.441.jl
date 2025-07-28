# Polynomial system saved on 2025-07-28T15:30:06.441
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:30:06.441
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
    0.5619241690363536 + _t56_x2_t_,
    0.5306938324430555 + _t56_x2ˍt_t_,
    -1.8103004425276428 + _t56_x1_t_,
    0.5619241261378805 + _t56_x1ˍt_t_,
    _t56_x1_t_ + _t56_x2ˍt_t_ + (-1 + _t56_x1_t_^2)*_t56_x2_t_*_tpb_,
    _t56_x1ˍt_t_ - _t56_x2_t_*_tpa_
]

