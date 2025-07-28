# Polynomial system saved on 2025-07-28T15:17:22.436
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:17:22.436
# num_equations: 12

# Variables
varlist_str = """
_tpk21_
_tpke_
_t167_C1_t_
_t167_C2_t_
_t167_C1ˍt_t_
_t167_C1ˍtt_t_
_t167_C2ˍt_t_
_t334_C1_t_
_t334_C2_t_
_t334_C1ˍt_t_
_t334_C1ˍtt_t_
_t334_C2ˍt_t_
"""
@variables _tpk21_ _tpke_ _t167_C1_t_ _t167_C2_t_ _t167_C1ˍt_t_ _t167_C1ˍtt_t_ _t167_C2ˍt_t_ _t334_C1_t_ _t334_C2_t_ _t334_C1ˍt_t_ _t334_C1ˍtt_t_ _t334_C2ˍt_t_
varlist = [_tpk21__tpke__t167_C1_t__t167_C2_t__t167_C1ˍt_t__t167_C1ˍtt_t__t167_C2ˍt_t__t334_C1_t__t334_C2_t__t334_C1ˍt_t__t334_C1ˍtt_t__t334_C2ˍt_t_]

# Polynomial System
poly_system = [
    -1.2629929138763212 + _t167_C1_t_,
    0.05532386634376033 + _t167_C1ˍt_t_,
    -0.0024294449277143955 + _t167_C1ˍtt_t_,
    0.8379005220039515_t167_C1_t_ + _t167_C1ˍt_t_ + _t167_C1_t_*_tpke_ - 8.23897036887765_t167_C2_t_*_tpk21_,
    0.8379005220039515_t167_C1ˍt_t_ + _t167_C1ˍtt_t_ + _t167_C1ˍt_t_*_tpke_ - 8.23897036887765_t167_C2ˍt_t_*_tpk21_,
    -0.10169966445917612_t167_C1_t_ + _t167_C2ˍt_t_ + _t167_C2_t_*_tpk21_,
    -0.6258193071350381 + _t334_C1_t_,
    0.02740966792378706 + _t334_C1ˍt_t_,
    -0.0012005815994324924 + _t334_C1ˍtt_t_,
    0.8379005220039515_t334_C1_t_ + _t334_C1ˍt_t_ + _t334_C1_t_*_tpke_ - 8.23897036887765_t334_C2_t_*_tpk21_,
    0.8379005220039515_t334_C1ˍt_t_ + _t334_C1ˍtt_t_ + _t334_C1ˍt_t_*_tpke_ - 8.23897036887765_t334_C2ˍt_t_*_tpk21_,
    -0.10169966445917612_t334_C1_t_ + _t334_C2ˍt_t_ + _t334_C2_t_*_tpk21_
]

