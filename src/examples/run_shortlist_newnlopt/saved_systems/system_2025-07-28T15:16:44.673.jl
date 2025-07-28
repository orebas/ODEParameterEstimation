# Polynomial system saved on 2025-07-28T15:16:44.681
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:16:44.673
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
    -2.095326216975992 + _t56_C1_t_,
    0.15773267658009107 + _t56_C1ˍt_t_,
    -0.06337803271156528 + _t56_C1ˍtt_t_,
    0.05111138324251513 + _t56_C1ˍttt_t_,
    0.43480123242760915_t56_C1_t_ + _t56_C1ˍt_t_ + _t56_C1_t_*_tpke_ - 1.0276277857669343_t56_C2_t_*_tpk21_,
    0.43480123242760915_t56_C1ˍt_t_ + _t56_C1ˍtt_t_ + _t56_C1ˍt_t_*_tpke_ - 1.0276277857669343_t56_C2ˍt_t_*_tpk21_,
    0.43480123242760915_t56_C1ˍtt_t_ + _t56_C1ˍttt_t_ + _t56_C1ˍtt_t_*_tpke_ - 1.0276277857669343_t56_C2ˍtt_t_*_tpk21_,
    -0.4231115959005627_t56_C1_t_ + _t56_C2ˍt_t_ + _t56_C2_t_*_tpk21_,
    -0.4231115959005627_t56_C1ˍt_t_ + _t56_C2ˍtt_t_ + _t56_C2ˍt_t_*_tpk21_
]

