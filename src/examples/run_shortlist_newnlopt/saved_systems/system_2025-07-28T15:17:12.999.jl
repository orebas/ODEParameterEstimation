# Polynomial system saved on 2025-07-28T15:17:12.999
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:12.999
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t334_C1_t_
_t334_C2_t_
_t334_C1ˍt_t_
_t334_C1ˍtt_t_
_t334_C1ˍttt_t_
_t334_C2ˍt_t_
_t334_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t334_C1_t_ _t334_C2_t_ _t334_C1ˍt_t_ _t334_C1ˍtt_t_ _t334_C1ˍttt_t_ _t334_C2ˍt_t_ _t334_C2ˍtt_t_
varlist = [_tpk21__tpke__t334_C1_t__t334_C2_t__t334_C1ˍt_t__t334_C1ˍtt_t__t334_C1ˍttt_t__t334_C2ˍt_t__t334_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -0.6258193085668129 + _t334_C1_t_,
    0.02740968400490834 + _t334_C1ˍt_t_,
    -0.0012004915332642918 + _t334_C1ˍtt_t_,
    5.257922971779738e-5 + _t334_C1ˍttt_t_,
    0.3178482367350154_t334_C1_t_ + _t334_C1ˍt_t_ + _t334_C1_t_*_tpke_ - 12.286619069583274_t334_C2_t_*_tpk21_,
    0.3178482367350154_t334_C1ˍt_t_ + _t334_C1ˍtt_t_ + _t334_C1ˍt_t_*_tpke_ - 12.286619069583274_t334_C2ˍt_t_*_tpk21_,
    0.3178482367350154_t334_C1ˍtt_t_ + _t334_C1ˍttt_t_ + _t334_C1ˍtt_t_*_tpke_ - 12.286619069583274_t334_C2ˍtt_t_*_tpk21_,
    -0.02586946294460123_t334_C1_t_ + _t334_C2ˍt_t_ + _t334_C2_t_*_tpk21_,
    -0.02586946294460123_t334_C1ˍt_t_ + _t334_C2ˍtt_t_ + _t334_C2ˍt_t_*_tpk21_
]

