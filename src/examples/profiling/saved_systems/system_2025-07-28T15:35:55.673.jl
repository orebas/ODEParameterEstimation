# Polynomial system saved on 2025-07-28T15:35:55.673
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:35:55.673
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t156_x1_t_
_t156_x2_t_
_t156_x2ˍt_t_
_t156_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t156_x1_t_ _t156_x2_t_ _t156_x2ˍt_t_ _t156_x1ˍt_t_
varlist = [_tpa__tpb__t156_x1_t__t156_x2_t__t156_x2ˍt_t__t156_x1ˍt_t_]

# Polynomial System
poly_system = [
    0.005276241336618738 + _t156_x2_t_,
    0.461870687106984 + _t156_x2ˍt_t_,
    0.577338358883834 + _t156_x1_t_,
    -0.002110496534649897 + _t156_x1ˍt_t_,
    _t156_x2ˍt_t_ - _t156_x1_t_*_tpb_,
    _t156_x1ˍt_t_ + _t156_x2_t_*_tpa_
]

