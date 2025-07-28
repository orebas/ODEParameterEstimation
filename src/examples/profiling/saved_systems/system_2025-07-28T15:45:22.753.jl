# Polynomial system saved on 2025-07-28T15:45:22.754
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:45:22.753
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t45_x1_t_
_t45_x2_t_
_t45_x1ˍt_t_
_t45_x2ˍt_t_
_t112_x1_t_
_t112_x2_t_
_t112_x1ˍt_t_
_t112_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t45_x1_t_ _t45_x2_t_ _t45_x1ˍt_t_ _t45_x2ˍt_t_ _t112_x1_t_ _t112_x2_t_ _t112_x1ˍt_t_ _t112_x2ˍt_t_
varlist = [_tpa__tpb__t45_x1_t__t45_x2_t__t45_x1ˍt_t__t45_x2ˍt_t__t112_x1_t__t112_x2_t__t112_x1ˍt_t__t112_x2ˍt_t_]

# Polynomial System
poly_system = [
    0.647557955749138 + 3.0_t45_x1_t_ - 0.25_t45_x2_t_,
    -1.201250228786821 + 2.0_t45_x1_t_ + 0.5_t45_x2_t_,
    1.9642401210715748 + 2.0_t45_x1ˍt_t_ + 0.5_t45_x2ˍt_t_,
    _t45_x1ˍt_t_ + _t45_x2_t_*_tpa_,
    _t45_x2ˍt_t_ - _t45_x1_t_*_tpb_,
    4.593643411645813 + 3.0_t112_x1_t_ - 0.25_t112_x2_t_,
    2.118261422274006 + 2.0_t112_x1_t_ + 0.5_t112_x2_t_,
    1.6982785319897205 + 2.0_t112_x1ˍt_t_ + 0.5_t112_x2ˍt_t_,
    _t112_x1ˍt_t_ + _t112_x2_t_*_tpa_,
    _t112_x2ˍt_t_ - _t112_x1_t_*_tpb_
]

