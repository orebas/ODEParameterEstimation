# Polynomial system saved on 2025-07-28T15:17:18.573
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:17:18.572
# num_equations: 12

# Variables
varlist_str = """
_tpk21_
_tpke_
_t111_C1_t_
_t111_C2_t_
_t111_C1ˍt_t_
_t111_C1ˍtt_t_
_t111_C2ˍt_t_
_t278_C1_t_
_t278_C2_t_
_t278_C1ˍt_t_
_t278_C1ˍtt_t_
_t278_C2ˍt_t_
"""
@variables _tpk21_ _tpke_ _t111_C1_t_ _t111_C2_t_ _t111_C1ˍt_t_ _t111_C1ˍtt_t_ _t111_C2ˍt_t_ _t278_C1_t_ _t278_C2_t_ _t278_C1ˍt_t_ _t278_C1ˍtt_t_ _t278_C2ˍt_t_
varlist = [_tpk21__tpke__t111_C1_t__t111_C2_t__t111_C1ˍt_t__t111_C1ˍtt_t__t111_C2ˍt_t__t278_C1_t__t278_C2_t__t278_C1ˍt_t__t278_C1ˍtt_t__t278_C2ˍt_t_]

# Polynomial System
poly_system = [
    -1.599175604552148 + _t111_C1_t_,
    0.07075856335231688 + _t111_C1ˍt_t_,
    -0.0037151024481458686 + _t111_C1ˍtt_t_,
    0.13837064481936256_t111_C1_t_ + _t111_C1ˍt_t_ + _t111_C1_t_*_tpke_ - 0.3844685095175626_t111_C2_t_*_tpk21_,
    0.13837064481936256_t111_C1ˍt_t_ + _t111_C1ˍtt_t_ + _t111_C1ˍt_t_*_tpke_ - 0.3844685095175626_t111_C2ˍt_t_*_tpk21_,
    -0.359901113859734_t111_C1_t_ + _t111_C2ˍt_t_ + _t111_C2_t_*_tpk21_,
    -0.7919673476310036 + _t278_C1_t_,
    0.03468665605286491 + _t278_C1ˍt_t_,
    -0.0015191930550894548 + _t278_C1ˍtt_t_,
    0.13837064481936256_t278_C1_t_ + _t278_C1ˍt_t_ + _t278_C1_t_*_tpke_ - 0.3844685095175626_t278_C2_t_*_tpk21_,
    0.13837064481936256_t278_C1ˍt_t_ + _t278_C1ˍtt_t_ + _t278_C1ˍt_t_*_tpke_ - 0.3844685095175626_t278_C2ˍt_t_*_tpk21_,
    -0.359901113859734_t278_C1_t_ + _t278_C2ˍt_t_ + _t278_C2_t_*_tpk21_
]

