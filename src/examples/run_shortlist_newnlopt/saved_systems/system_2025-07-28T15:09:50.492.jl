# Polynomial system saved on 2025-07-28T15:09:50.492
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:09:50.492
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t223_x1_t_
_t223_x2_t_
_t223_x3_t_
_t223_x2ˍt_t_
_t223_x3ˍt_t_
_t223_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t223_x1_t_ _t223_x2_t_ _t223_x3_t_ _t223_x2ˍt_t_ _t223_x3ˍt_t_ _t223_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t223_x1_t__t223_x2_t__t223_x3_t__t223_x2ˍt_t__t223_x3ˍt_t__t223_x1ˍt_t_]

# Polynomial System
poly_system = [
    -11.336193722322555 + _t223_x2_t_^3,
    4.306720130061733 + 3(_t223_x2_t_^2)*_t223_x2ˍt_t_,
    -23.630403649202865 + _t223_x3_t_^3,
    10.541615467522758 + 3(_t223_x3_t_^2)*_t223_x3ˍt_t_,
    -2.8777408034434164 + _t223_x1_t_^3,
    1.3634674572229266 + 3(_t223_x1_t_^2)*_t223_x1ˍt_t_,
    _t223_x2ˍt_t_ + _t223_x1_t_*_tpb_,
    _t223_x3ˍt_t_ + _t223_x1_t_*_tpc_,
    _t223_x1ˍt_t_ + _t223_x2_t_*_tpa_
]

