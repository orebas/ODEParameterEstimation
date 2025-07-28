# Polynomial system saved on 2025-07-28T15:38:09.277
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:38:09.277
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t156_x1_t_
_t156_x2_t_
_t156_x3_t_
_t156_x2ˍt_t_
_t156_x3ˍt_t_
_t156_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t156_x1_t_ _t156_x2_t_ _t156_x3_t_ _t156_x2ˍt_t_ _t156_x3ˍt_t_ _t156_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t156_x1_t__t156_x2_t__t156_x3_t__t156_x2ˍt_t__t156_x3ˍt_t__t156_x1ˍt_t_]

# Polynomial System
poly_system = [
    -6.15970418717335 + _t156_x2_t_^3,
    2.1902409582633084 + 3(_t156_x2_t_^2)*_t156_x2ˍt_t_,
    -11.38534735329201 + _t156_x3_t_^3,
    4.948096509333039 + 3(_t156_x3_t_^2)*_t156_x3ˍt_t_,
    -1.2820217559888831 + _t156_x1_t_^3,
    0.6489896406239064 + 3(_t156_x1_t_^2)*_t156_x1ˍt_t_,
    _t156_x2ˍt_t_ + _t156_x1_t_*_tpb_,
    _t156_x3ˍt_t_ + _t156_x1_t_*_tpc_,
    _t156_x1ˍt_t_ + _t156_x2_t_*_tpa_
]

