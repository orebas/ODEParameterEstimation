# Polynomial system saved on 2025-07-28T15:36:16.129
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:36:16.129
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t156_x1_t_
_t156_x2_t_
_t156_x1ˍt_t_
_t156_x2ˍt_t_
_t201_x1_t_
_t201_x2_t_
_t201_x1ˍt_t_
_t201_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t156_x1_t_ _t156_x2_t_ _t156_x1ˍt_t_ _t156_x2ˍt_t_ _t201_x1_t_ _t201_x2_t_ _t201_x1ˍt_t_ _t201_x2ˍt_t_
varlist = [_tpa__tpb__t156_x1_t__t156_x2_t__t156_x1ˍt_t__t156_x2ˍt_t__t201_x1_t__t201_x2_t__t201_x1ˍt_t__t201_x2ˍt_t_]

# Polynomial System
poly_system = [
    5.1925424316150455 + 3.0_t156_x1_t_ - 0.25_t156_x2_t_,
    3.4710925450052206 + 2.0_t156_x1_t_ + 0.5_t156_x2_t_,
    0.681531574155388 + 2.0_t156_x1ˍt_t_ + 0.5_t156_x2ˍt_t_,
    _t156_x1ˍt_t_ + _t156_x2_t_*_tpa_,
    _t156_x2ˍt_t_ - _t156_x1_t_*_tpb_,
    3.7943651140729178 + 3.0_t201_x1_t_ - 0.25_t201_x2_t_,
    3.507608197263041 + 2.0_t201_x1_t_ + 0.5_t201_x2_t_,
    -0.6188218023090238 + 2.0_t201_x1ˍt_t_ + 0.5_t201_x2ˍt_t_,
    _t201_x1ˍt_t_ + _t201_x2_t_*_tpa_,
    _t201_x2ˍt_t_ - _t201_x1_t_*_tpb_
]

