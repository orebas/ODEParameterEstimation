# Polynomial system saved on 2025-07-28T15:16:42.822
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:16:42.821
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
    -2.0953261108910217 + _t56_C1_t_,
    0.15773056103345715 + _t56_C1ˍt_t_,
    -0.06337861596334791 + _t56_C1ˍtt_t_,
    0.05114706896287276 + _t56_C1ˍttt_t_,
    0.19909690873186126_t56_C1_t_ + _t56_C1ˍt_t_ + _t56_C1_t_*_tpke_ - 0.24717723326836977_t56_C2_t_*_tpk21_,
    0.19909690873186126_t56_C1ˍt_t_ + _t56_C1ˍtt_t_ + _t56_C1ˍt_t_*_tpke_ - 0.24717723326836977_t56_C2ˍt_t_*_tpk21_,
    0.19909690873186126_t56_C1ˍtt_t_ + _t56_C1ˍttt_t_ + _t56_C1ˍtt_t_*_tpke_ - 0.24717723326836977_t56_C2ˍtt_t_*_tpk21_,
    -0.8054823905067913_t56_C1_t_ + _t56_C2ˍt_t_ + _t56_C2_t_*_tpk21_,
    -0.8054823905067913_t56_C1ˍt_t_ + _t56_C2ˍtt_t_ + _t56_C2ˍt_t_*_tpk21_
]

