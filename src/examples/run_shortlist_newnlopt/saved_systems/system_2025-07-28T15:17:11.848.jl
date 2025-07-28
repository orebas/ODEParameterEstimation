# Polynomial system saved on 2025-07-28T15:17:11.848
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:11.848
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t56_C1_t_
_t56_C2_t_
_t56_C1ˍt_t_
_t56_C1ˍtt_t_
_t56_C1ˍttt_t_
_t56_C2ˍt_t_
_t56_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t56_C1_t_ _t56_C2_t_ _t56_C1ˍt_t_ _t56_C1ˍtt_t_ _t56_C1ˍttt_t_ _t56_C2ˍt_t_ _t56_C2ˍtt_t_
varlist = [_tpk21__tpke__t56_C1_t__t56_C2_t__t56_C1ˍt_t__t56_C1ˍtt_t__t56_C1ˍttt_t__t56_C2ˍt_t__t56_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -2.0953259070818344 + _t56_C1_t_,
    0.1577314879332583 + _t56_C1ˍt_t_,
    -0.0633836176242184 + _t56_C1ˍtt_t_,
    0.05113032506413617 + _t56_C1ˍttt_t_,
    0.20527477100496283_t56_C1_t_ + _t56_C1ˍt_t_ + _t56_C1_t_*_tpke_ - 1.1177892513286165_t56_C2_t_*_tpk21_,
    0.20527477100496283_t56_C1ˍt_t_ + _t56_C1ˍtt_t_ + _t56_C1ˍt_t_*_tpke_ - 1.1177892513286165_t56_C2ˍt_t_*_tpk21_,
    0.20527477100496283_t56_C1ˍtt_t_ + _t56_C1ˍttt_t_ + _t56_C1ˍtt_t_*_tpke_ - 1.1177892513286165_t56_C2ˍtt_t_*_tpk21_,
    -0.18364353634727743_t56_C1_t_ + _t56_C2ˍt_t_ + _t56_C2_t_*_tpk21_,
    -0.18364353634727743_t56_C1ˍt_t_ + _t56_C2ˍtt_t_ + _t56_C2ˍt_t_*_tpk21_
]

