# Polynomial system saved on 2025-07-28T15:45:33.509
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:45:33.509
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t179_x1_t_
_t179_x2_t_
_t179_x1ˍt_t_
_t179_x2ˍt_t_
_t201_x1_t_
_t201_x2_t_
_t201_x1ˍt_t_
_t201_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t179_x1_t_ _t179_x2_t_ _t179_x1ˍt_t_ _t179_x2ˍt_t_ _t201_x1_t_ _t201_x2_t_ _t201_x1ˍt_t_ _t201_x2ˍt_t_
varlist = [_tpa__tpb__t179_x1_t__t179_x2_t__t179_x1ˍt_t__t179_x2ˍt_t__t201_x1_t__t201_x2_t__t201_x1ˍt_t__t201_x2ˍt_t_]

# Polynomial System
poly_system = [
    4.715025025906351 + 3.0_t179_x1_t_ - 0.25_t179_x2_t_,
    3.674091962607646 + 2.0_t179_x1_t_ + 0.5_t179_x2_t_,
    0.018317053752277726 + 2.0_t179_x1ˍt_t_ + 0.5_t179_x2ˍt_t_,
    _t179_x1ˍt_t_ + _t179_x2_t_*_tpa_,
    _t179_x2ˍt_t_ - _t179_x1_t_*_tpb_,
    3.7943652664796677 + 3.0_t201_x1_t_ - 0.25_t201_x2_t_,
    3.50760829754336 + 2.0_t201_x1_t_ + 0.5_t201_x2_t_,
    -0.6188185926202279 + 2.0_t201_x1ˍt_t_ + 0.5_t201_x2ˍt_t_,
    _t201_x1ˍt_t_ + _t201_x2_t_*_tpa_,
    _t201_x2ˍt_t_ - _t201_x1_t_*_tpb_
]

