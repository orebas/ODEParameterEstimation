# Polynomial system saved on 2025-07-28T15:09:47.542
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:09:47.542
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
    -11.336193691387184 + _t223_x2_t_^3,
    4.306719449808587 + 3(_t223_x2_t_^2)*_t223_x2ˍt_t_,
    -23.63040226834008 + _t223_x3_t_^3,
    10.54161508325849 + 3(_t223_x3_t_^2)*_t223_x3ˍt_t_,
    -2.8777408071164308 + _t223_x1_t_^3,
    1.3634673428576716 + 3(_t223_x1_t_^2)*_t223_x1ˍt_t_,
    _t223_x2ˍt_t_ + _t223_x1_t_*_tpb_,
    _t223_x3ˍt_t_ + _t223_x1_t_*_tpc_,
    _t223_x1ˍt_t_ + _t223_x2_t_*_tpa_
]

