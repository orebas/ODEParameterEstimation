# Polynomial system saved on 2025-07-28T15:49:01.736
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:49:01.723
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t112_x1_t_
_t112_x2_t_
_t112_x3_t_
_t112_x2ˍt_t_
_t112_x3ˍt_t_
_t112_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t112_x1_t_ _t112_x2_t_ _t112_x3_t_ _t112_x2ˍt_t_ _t112_x3ˍt_t_ _t112_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t112_x1_t__t112_x2_t__t112_x3_t__t112_x2ˍt_t__t112_x3ˍt_t__t112_x1ˍt_t_]

# Polynomial System
poly_system = [
    -9.198779838671722 + _t112_x2_t_^3,
    3.4295523479371264 + 3(_t112_x2_t_^2)*_t112_x2ˍt_t_,
    -18.46106850256893 + _t112_x3_t_^3,
    8.184888976612607 + 3(_t112_x3_t_^2)*_t112_x3ˍt_t_,
    -2.2069772242600934 + _t112_x1_t_^3,
    1.0655237265451765 + 3(_t112_x1_t_^2)*_t112_x1ˍt_t_,
    _t112_x2ˍt_t_ + _t112_x1_t_*_tpb_,
    _t112_x3ˍt_t_ + _t112_x1_t_*_tpc_,
    _t112_x1ˍt_t_ + _t112_x2_t_*_tpa_
]

