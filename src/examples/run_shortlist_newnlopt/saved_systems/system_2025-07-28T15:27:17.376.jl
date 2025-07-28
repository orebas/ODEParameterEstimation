# Polynomial system saved on 2025-07-28T15:27:17.376
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:27:17.376
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t111_x1_t_
_t111_x2_t_
_t111_x2ˍt_t_
_t111_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t111_x1_t_ _t111_x2_t_ _t111_x2ˍt_t_ _t111_x1ˍt_t_
varlist = [_tpa__tpb__t111_x1_t__t111_x2_t__t111_x2ˍt_t__t111_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.8084964028477923 + _t111_x2_t_,
    0.5885011007306066 + _t111_x2ˍt_t_,
    0.5885011032770886 + _t111_x1_t_,
    0.8084964416464002 + _t111_x1ˍt_t_,
    -_t111_x1_t_ + _t111_x2ˍt_t_*_tpb_,
    _t111_x1ˍt_t_ + _t111_x2_t_*_tpa_
]

