# Polynomial system saved on 2025-07-28T15:08:53.844
using Symbolics
using StaticArrays

# Metadata
# num_variables: 15
# timestamp: 2025-07-28T15:08:53.843
# num_equations: 15

# Variables
varlist_str = """
_tpa_
_tpb_
_t167_x1_t_
_t167_x2_t_
_t167_x3_t_
_t167_x3ˍt_t_
_t167_x3ˍtt_t_
_t167_x3ˍttt_t_
_t167_x3ˍtttt_t_
_t167_x1ˍt_t_
_t167_x2ˍt_t_
_t167_x1ˍtt_t_
_t167_x2ˍtt_t_
_t167_x2ˍttt_t_
_t167_x1ˍttt_t_
"""
@variables _tpa_ _tpb_ _t167_x1_t_ _t167_x2_t_ _t167_x3_t_ _t167_x3ˍt_t_ _t167_x3ˍtt_t_ _t167_x3ˍttt_t_ _t167_x3ˍtttt_t_ _t167_x1ˍt_t_ _t167_x2ˍt_t_ _t167_x1ˍtt_t_ _t167_x2ˍtt_t_ _t167_x2ˍttt_t_ _t167_x1ˍttt_t_
varlist = [_tpa__tpb__t167_x1_t__t167_x2_t__t167_x3_t__t167_x3ˍt_t__t167_x3ˍtt_t__t167_x3ˍttt_t__t167_x3ˍtttt_t__t167_x1ˍt_t__t167_x2ˍt_t__t167_x1ˍtt_t__t167_x2ˍtt_t__t167_x2ˍttt_t__t167_x1ˍttt_t_]

# Polynomial System
poly_system = [
    -6.689610413169934 + _t167_x3_t_,
    -1.7626053041752057 + _t167_x3ˍt_t_,
    -0.2000527386800286 + _t167_x3ˍtt_t_,
    -0.055257379941451745 + _t167_x3ˍttt_t_,
    -0.009526792801352713 + _t167_x3ˍtttt_t_,
    -0.8726295356745197(_t167_x1_t_ + _t167_x2_t_) + _t167_x3ˍt_t_,
    -0.8726295356745197(_t167_x1ˍt_t_ + _t167_x2ˍt_t_) + _t167_x3ˍtt_t_,
    -0.8726295356745197(_t167_x1ˍtt_t_ + _t167_x2ˍtt_t_) + _t167_x3ˍttt_t_,
    -0.8726295356745197(_t167_x1ˍttt_t_ + _t167_x2ˍttt_t_) + _t167_x3ˍtttt_t_,
    _t167_x1ˍt_t_ + _t167_x1_t_*_tpa_,
    _t167_x2ˍt_t_ - _t167_x2_t_*_tpb_,
    _t167_x1ˍtt_t_ + _t167_x1ˍt_t_*_tpa_,
    _t167_x2ˍtt_t_ - _t167_x2ˍt_t_*_tpb_,
    _t167_x2ˍttt_t_ - _t167_x2ˍtt_t_*_tpb_,
    _t167_x1ˍttt_t_ + _t167_x1ˍtt_t_*_tpa_
]

