# Polynomial system saved on 2025-07-28T15:28:34.471
using Symbolics
using StaticArrays

# Metadata
# num_variables: 7
# timestamp: 2025-07-28T15:28:34.471
# num_equations: 7

# Variables
varlist_str = """
_tpa_
_tpb_
_t167_X_t_
_t167_Y_t_
_t167_Xˍt_t_
_t167_Xˍtt_t_
_t167_Yˍt_t_
"""
@variables _tpa_ _tpb_ _t167_X_t_ _t167_Y_t_ _t167_Xˍt_t_ _t167_Xˍtt_t_ _t167_Yˍt_t_
varlist = [_tpa__tpb__t167_X_t__t167_Y_t__t167_Xˍt_t__t167_Xˍtt_t__t167_Yˍt_t_]

# Polynomial System
poly_system = [
    -2.399316822149741 + _t167_Y_t_,
    -2.822156088366449 + _t167_X_t_,
    -8.82170384291143 + _t167_Xˍt_t_,
    0.6154010890577114 + _t167_Xˍtt_t_,
    -1.0 + _t167_Xˍt_t_ + _t167_X_t_*(1 + _tpb_) - (_t167_X_t_^2)*_t167_Y_t_*_tpa_,
    _t167_Xˍtt_t_ - _t167_Xˍt_t_*(-1 - _tpb_) - (_t167_X_t_^2)*_t167_Yˍt_t_*_tpa_ - 2_t167_X_t_*_t167_Xˍt_t_*_t167_Y_t_*_tpa_,
    _t167_Yˍt_t_ - _t167_X_t_*_tpb_ + (_t167_X_t_^2)*_t167_Y_t_*_tpa_
]

