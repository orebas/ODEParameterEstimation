# Polynomial system saved on 2025-07-28T15:17:07.649
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:07.649
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
    -0.7919673514618498 + _t278_C1_t_,
    0.03468665656075761 + _t278_C1ˍt_t_,
    -0.0015191885722038235 + _t278_C1ˍtt_t_,
    6.64098929633356e-5 + _t278_C1ˍttt_t_,
    0.05707592558313257_t278_C1_t_ + _t278_C1ˍt_t_ + _t278_C1_t_*_tpke_ - 0.8923223359538089_t278_C2_t_*_tpk21_,
    0.05707592558313257_t278_C1ˍt_t_ + _t278_C1ˍtt_t_ + _t278_C1ˍt_t_*_tpke_ - 0.8923223359538089_t278_C2ˍt_t_*_tpk21_,
    0.05707592558313257_t278_C1ˍtt_t_ + _t278_C1ˍttt_t_ + _t278_C1ˍtt_t_*_tpke_ - 0.8923223359538089_t278_C2ˍtt_t_*_tpk21_,
    -0.06396334965898144_t278_C1_t_ + _t278_C2ˍt_t_ + _t278_C2_t_*_tpk21_,
    -0.06396334965898144_t278_C1ˍt_t_ + _t278_C2ˍtt_t_ + _t278_C2ˍt_t_*_tpk21_
]

