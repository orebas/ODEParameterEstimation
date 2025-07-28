# Polynomial system saved on 2025-07-28T15:17:05.802
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:05.802
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t167_C1_t_
_t167_C2_t_
_t167_C1ˍt_t_
_t167_C1ˍtt_t_
_t167_C1ˍttt_t_
_t167_C2ˍt_t_
_t167_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t167_C1_t_ _t167_C2_t_ _t167_C1ˍt_t_ _t167_C1ˍtt_t_ _t167_C1ˍttt_t_ _t167_C2ˍt_t_ _t167_C2ˍtt_t_
varlist = [_tpk21__tpke__t167_C1_t__t167_C2_t__t167_C1ˍt_t__t167_C1ˍtt_t__t167_C1ˍttt_t__t167_C2ˍt_t__t167_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -1.2629928903018832 + _t167_C1_t_,
    0.055323888733320885 + _t167_C1ˍt_t_,
    -0.002429084678861339 + _t167_C1ˍtt_t_,
    0.00011011453694692122 + _t167_C1ˍttt_t_,
    0.7927222746995694_t167_C1_t_ + _t167_C1ˍt_t_ + _t167_C1_t_*_tpke_ - 3.361519939003638_t167_C2_t_*_tpk21_,
    0.7927222746995694_t167_C1ˍt_t_ + _t167_C1ˍtt_t_ + _t167_C1ˍt_t_*_tpke_ - 3.361519939003638_t167_C2ˍt_t_*_tpk21_,
    0.7927222746995694_t167_C1ˍtt_t_ + _t167_C1ˍttt_t_ + _t167_C1ˍtt_t_*_tpke_ - 3.361519939003638_t167_C2ˍtt_t_*_tpk21_,
    -0.23582257106424723_t167_C1_t_ + _t167_C2ˍt_t_ + _t167_C2_t_*_tpk21_,
    -0.23582257106424723_t167_C1ˍt_t_ + _t167_C2ˍtt_t_ + _t167_C2ˍt_t_*_tpk21_
]

