# Polynomial system saved on 2025-07-28T15:17:12.552
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:12.552
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t223_C1_t_
_t223_C2_t_
_t223_C1ˍt_t_
_t223_C1ˍtt_t_
_t223_C1ˍttt_t_
_t223_C2ˍt_t_
_t223_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t223_C1_t_ _t223_C2_t_ _t223_C1ˍt_t_ _t223_C1ˍtt_t_ _t223_C1ˍttt_t_ _t223_C2ˍt_t_ _t223_C2ˍtt_t_
varlist = [_tpk21__tpke__t223_C1_t__t223_C2_t__t223_C1ˍt_t__t223_C1ˍtt_t__t223_C1ˍttt_t__t223_C2ˍt_t__t223_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -0.9980207941150222 + _t223_C1_t_,
    0.043711466442336144 + _t223_C1ˍt_t_,
    -0.0019145400187998707 + _t223_C1ˍtt_t_,
    8.390602523744572e-5 + _t223_C1ˍttt_t_,
    0.41502645668359306_t223_C1_t_ + _t223_C1ˍt_t_ + _t223_C1_t_*_tpke_ - 5.681062267666337_t223_C2_t_*_tpk21_,
    0.41502645668359306_t223_C1ˍt_t_ + _t223_C1ˍtt_t_ + _t223_C1ˍt_t_*_tpke_ - 5.681062267666337_t223_C2ˍt_t_*_tpk21_,
    0.41502645668359306_t223_C1ˍtt_t_ + _t223_C1ˍttt_t_ + _t223_C1ˍtt_t_*_tpke_ - 5.681062267666337_t223_C2ˍtt_t_*_tpk21_,
    -0.07305437559551295_t223_C1_t_ + _t223_C2ˍt_t_ + _t223_C2_t_*_tpk21_,
    -0.07305437559551295_t223_C1ˍt_t_ + _t223_C2ˍtt_t_ + _t223_C2ˍt_t_*_tpk21_
]

