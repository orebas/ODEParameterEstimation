# Polynomial system saved on 2025-07-28T15:36:09.966
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:36:09.966
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t179_x1_t_
_t179_x2_t_
_t179_x1ˍt_t_
_t179_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t179_x1_t_ _t179_x2_t_ _t179_x1ˍt_t_ _t179_x2ˍt_t_
varlist = [_tpa__tpb__t179_x1_t__t179_x2_t__t179_x1ˍt_t__t179_x2ˍt_t_]

# Polynomial System
poly_system = [
    4.715025062702172 + 3.0_t179_x1_t_ - 0.25_t179_x2_t_,
    -1.282938958247367 + 3.0_t179_x1ˍt_t_ - 0.25_t179_x2ˍt_t_,
    3.674091934441038 + 2.0_t179_x1_t_ + 0.5_t179_x2_t_,
    0.018316831824847668 + 2.0_t179_x1ˍt_t_ + 0.5_t179_x2ˍt_t_,
    _t179_x1ˍt_t_ + _t179_x2_t_*_tpa_,
    _t179_x2ˍt_t_ - _t179_x1_t_*_tpb_
]

