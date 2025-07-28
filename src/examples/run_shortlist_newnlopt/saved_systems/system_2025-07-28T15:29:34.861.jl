# Polynomial system saved on 2025-07-28T15:29:34.862
using Symbolics
using StaticArrays

# Metadata
# num_variables: 8
# timestamp: 2025-07-28T15:29:34.861
# num_equations: 8

# Variables
varlist_str = """
_tpa_
_tpb_
_t167_X_t_
_t167_Y_t_
_t167_Xˍt_t_
_t334_X_t_
_t334_Y_t_
_t334_Xˍt_t_
"""
@variables _tpa_ _tpb_ _t167_X_t_ _t167_Y_t_ _t167_Xˍt_t_ _t334_X_t_ _t334_Y_t_ _t334_Xˍt_t_
varlist = [_tpa__tpb__t167_X_t__t167_Y_t__t167_Xˍt_t__t334_X_t__t334_Y_t__t334_Xˍt_t_]

# Polynomial System
poly_system = [
    -2.3993168565547673 + _t167_Y_t_,
    -2.8221560824271785 + _t167_X_t_,
    -8.8217030459549 + _t167_Xˍt_t_,
    -1.0 + _t167_Xˍt_t_ + _t167_X_t_*(1 + _tpb_) - (_t167_X_t_^2)*_t167_Y_t_*_tpa_,
    -4.554684969450286 + _t334_Y_t_,
    -0.9110165620177405 + _t334_X_t_,
    -1.1361471658548696 + _t334_Xˍt_t_,
    -1.0 + _t334_Xˍt_t_ + _t334_X_t_*(1 + _tpb_) - (_t334_X_t_^2)*_t334_Y_t_*_tpa_
]

