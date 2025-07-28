# Polynomial system saved on 2025-07-28T15:17:12.782
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:12.781
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t278_C1_t_
_t278_C2_t_
_t278_C1ˍt_t_
_t278_C1ˍtt_t_
_t278_C1ˍttt_t_
_t278_C2ˍt_t_
_t278_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t278_C1_t_ _t278_C2_t_ _t278_C1ˍt_t_ _t278_C1ˍtt_t_ _t278_C1ˍttt_t_ _t278_C2ˍt_t_ _t278_C2ˍtt_t_
varlist = [_tpk21__tpke__t278_C1_t__t278_C2_t__t278_C1ˍt_t__t278_C1ˍtt_t__t278_C1ˍttt_t__t278_C2ˍt_t__t278_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -0.7919673474602148 + _t278_C1_t_,
    0.034686649842264924 + _t278_C1ˍt_t_,
    -0.0015192093282243024 + _t278_C1ˍtt_t_,
    6.653902638987727e-5 + _t278_C1ˍttt_t_,
    0.9292347853383378_t278_C1_t_ + _t278_C1ˍt_t_ + _t278_C1_t_*_tpke_ - 1.3948306363186926_t278_C2_t_*_tpk21_,
    0.9292347853383378_t278_C1ˍt_t_ + _t278_C1ˍtt_t_ + _t278_C1ˍt_t_*_tpke_ - 1.3948306363186926_t278_C2ˍt_t_*_tpk21_,
    0.9292347853383378_t278_C1ˍtt_t_ + _t278_C1ˍttt_t_ + _t278_C1ˍtt_t_*_tpke_ - 1.3948306363186926_t278_C2ˍtt_t_*_tpk21_,
    -0.6661990073510439_t278_C1_t_ + _t278_C2ˍt_t_ + _t278_C2_t_*_tpk21_,
    -0.6661990073510439_t278_C1ˍt_t_ + _t278_C2ˍtt_t_ + _t278_C2ˍt_t_*_tpk21_
]

