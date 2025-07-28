# Polynomial system saved on 2025-07-28T15:17:09.802
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:09.801
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t445_C1_t_
_t445_C2_t_
_t445_C1ˍt_t_
_t445_C1ˍtt_t_
_t445_C1ˍttt_t_
_t445_C2ˍt_t_
_t445_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t445_C1_t_ _t445_C2_t_ _t445_C1ˍt_t_ _t445_C1ˍtt_t_ _t445_C1ˍttt_t_ _t445_C2ˍt_t_ _t445_C2ˍtt_t_
varlist = [_tpk21__tpke__t445_C1_t__t445_C2_t__t445_C1ˍt_t__t445_C1ˍtt_t__t445_C1ˍttt_t__t445_C2ˍt_t__t445_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -0.39242654738463134 + _t445_C1_t_,
    0.01718752158591134 + _t445_C1ˍt_t_,
    -0.0007527035910115779 + _t445_C1ˍtt_t_,
    3.339332240436662e-5 + _t445_C1ˍttt_t_,
    0.8633655922045869_t445_C1_t_ + _t445_C1ˍt_t_ + _t445_C1_t_*_tpke_ - 3.897388026209919_t445_C2_t_*_tpk21_,
    0.8633655922045869_t445_C1ˍt_t_ + _t445_C1ˍtt_t_ + _t445_C1ˍt_t_*_tpke_ - 3.897388026209919_t445_C2ˍt_t_*_tpk21_,
    0.8633655922045869_t445_C1ˍtt_t_ + _t445_C1ˍttt_t_ + _t445_C1ˍtt_t_*_tpke_ - 3.897388026209919_t445_C2ˍtt_t_*_tpk21_,
    -0.22152415576751833_t445_C1_t_ + _t445_C2ˍt_t_ + _t445_C2_t_*_tpk21_,
    -0.22152415576751833_t445_C1ˍt_t_ + _t445_C2ˍtt_t_ + _t445_C2ˍt_t_*_tpk21_
]

