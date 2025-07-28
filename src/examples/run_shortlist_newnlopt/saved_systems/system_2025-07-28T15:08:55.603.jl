# Polynomial system saved on 2025-07-28T15:08:55.603
using Symbolics
using StaticArrays

# Metadata
# num_variables: 22
# timestamp: 2025-07-28T15:08:55.603
# num_equations: 22

# Variables
varlist_str = """
_tpa_
_tpb_
_t56_x1_t_
_t56_x2_t_
_t56_x3_t_
_t56_x3ˍt_t_
_t56_x3ˍtt_t_
_t56_x3ˍttt_t_
_t56_x1ˍt_t_
_t56_x2ˍt_t_
_t56_x1ˍtt_t_
_t56_x2ˍtt_t_
_t223_x1_t_
_t223_x2_t_
_t223_x3_t_
_t223_x3ˍt_t_
_t223_x3ˍtt_t_
_t223_x3ˍttt_t_
_t223_x1ˍt_t_
_t223_x2ˍt_t_
_t223_x1ˍtt_t_
_t223_x2ˍtt_t_
"""
@variables _tpa_ _tpb_ _t56_x1_t_ _t56_x2_t_ _t56_x3_t_ _t56_x3ˍt_t_ _t56_x3ˍtt_t_ _t56_x3ˍttt_t_ _t56_x1ˍt_t_ _t56_x2ˍt_t_ _t56_x1ˍtt_t_ _t56_x2ˍtt_t_ _t223_x1_t_ _t223_x2_t_ _t223_x3_t_ _t223_x3ˍt_t_ _t223_x3ˍtt_t_ _t223_x3ˍttt_t_ _t223_x1ˍt_t_ _t223_x2ˍt_t_ _t223_x1ˍtt_t_ _t223_x2ˍtt_t_
varlist = [_tpa__tpb__t56_x1_t__t56_x2_t__t56_x3_t__t56_x3ˍt_t__t56_x3ˍtt_t__t56_x3ˍttt_t__t56_x1ˍt_t__t56_x2ˍt_t__t56_x1ˍtt_t__t56_x2ˍtt_t__t223_x1_t__t223_x2_t__t223_x3_t__t223_x3ˍt_t__t223_x3ˍtt_t__t223_x3ˍttt_t__t223_x1ˍt_t__t223_x2ˍt_t__t223_x1ˍtt_t__t223_x2ˍtt_t_]

# Polynomial System
poly_system = [
    -4.8443402795272466 + _t56_x3_t_,
    -1.5725414185603637 + _t56_x3ˍt_t_,
    -0.14414126058126167 + _t56_x3ˍtt_t_,
    -0.04585860798751048 + _t56_x3ˍttt_t_,
    -0.5988182178775838(_t56_x1_t_ + _t56_x2_t_) + _t56_x3ˍt_t_,
    -0.5988182178775838(_t56_x1ˍt_t_ + _t56_x2ˍt_t_) + _t56_x3ˍtt_t_,
    -0.5988182178775838(_t56_x1ˍtt_t_ + _t56_x2ˍtt_t_) + _t56_x3ˍttt_t_,
    _t56_x1ˍt_t_ + _t56_x1_t_*_tpa_,
    _t56_x2ˍt_t_ - _t56_x2_t_*_tpb_,
    _t56_x1ˍtt_t_ + _t56_x1ˍt_t_*_tpa_,
    _t56_x2ˍtt_t_ - _t56_x2ˍt_t_*_tpb_,
    -7.709694862700794 + _t223_x3_t_,
    -1.8835865611389289 + _t223_x3ˍt_t_,
    -0.232552439131857 + _t223_x3ˍtt_t_,
    -0.06093018340515171 + _t223_x3ˍttt_t_,
    -0.5988182178775838(_t223_x1_t_ + _t223_x2_t_) + _t223_x3ˍt_t_,
    -0.5988182178775838(_t223_x1ˍt_t_ + _t223_x2ˍt_t_) + _t223_x3ˍtt_t_,
    -0.5988182178775838(_t223_x1ˍtt_t_ + _t223_x2ˍtt_t_) + _t223_x3ˍttt_t_,
    _t223_x1ˍt_t_ + _t223_x1_t_*_tpa_,
    _t223_x2ˍt_t_ - _t223_x2_t_*_tpb_,
    _t223_x1ˍtt_t_ + _t223_x1ˍt_t_*_tpa_,
    _t223_x2ˍtt_t_ - _t223_x2ˍt_t_*_tpb_
]

