# Polynomial system saved on 2025-07-28T15:18:24.673
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:18:24.673
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t167_x1_t_
_t167_x2_t_
_t167_x1ˍt_t_
_t167_x2ˍt_t_
_t334_x1_t_
_t334_x2_t_
_t334_x1ˍt_t_
_t334_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t167_x1_t_ _t167_x2_t_ _t167_x1ˍt_t_ _t167_x2ˍt_t_ _t334_x1_t_ _t334_x2_t_ _t334_x1ˍt_t_ _t334_x2ˍt_t_
varlist = [_tpa__tpb__t167_x1_t__t167_x2_t__t167_x1ˍt_t__t167_x2ˍt_t__t334_x1_t__t334_x2_t__t334_x1ˍt_t__t334_x2ˍt_t_]

# Polynomial System
poly_system = [
    2.2326717726395664 + 3.0_t167_x1_t_ - 0.25_t167_x2_t_,
    -0.05980953815515999 + 2.0_t167_x1_t_ + 0.5_t167_x2_t_,
    2.0781855711995 + 2.0_t167_x1ˍt_t_ + 0.5_t167_x2ˍt_t_,
    _t167_x1ˍt_t_ + _t167_x2_t_*_tpa_,
    _t167_x2ˍt_t_ - _t167_x1_t_*_tpb_,
    5.142608009601564 + 3.0_t334_x1_t_ - 0.25_t334_x2_t_,
    2.9418562996805075 + 2.0_t334_x1_t_ + 0.5_t334_x2_t_,
    1.2452124819403674 + 2.0_t334_x1ˍt_t_ + 0.5_t334_x2ˍt_t_,
    _t334_x1ˍt_t_ + _t334_x2_t_*_tpa_,
    _t334_x2ˍt_t_ - _t334_x1_t_*_tpb_
]

