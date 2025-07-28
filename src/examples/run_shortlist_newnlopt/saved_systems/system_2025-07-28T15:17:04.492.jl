# Polynomial system saved on 2025-07-28T15:17:04.492
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:04.492
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t111_C1_t_
_t111_C2_t_
_t111_C1ˍt_t_
_t111_C1ˍtt_t_
_t111_C1ˍttt_t_
_t111_C2ˍt_t_
_t111_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t111_C1_t_ _t111_C2_t_ _t111_C1ˍt_t_ _t111_C1ˍtt_t_ _t111_C1ˍttt_t_ _t111_C2ˍt_t_ _t111_C2ˍtt_t_
varlist = [_tpk21__tpke__t111_C1_t__t111_C2_t__t111_C1ˍt_t__t111_C1ˍtt_t__t111_C1ˍttt_t__t111_C2ˍt_t__t111_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -1.5991756555318697 + _t111_C1_t_,
    0.07075858971239712 + _t111_C1ˍt_t_,
    -0.003713778061214478 + _t111_C1ˍtt_t_,
    0.0006867918861610869 + _t111_C1ˍttt_t_,
    0.42185583802357607_t111_C1_t_ + _t111_C1ˍt_t_ + _t111_C1_t_*_tpke_ - 0.7915942754515536_t111_C2_t_*_tpk21_,
    0.42185583802357607_t111_C1ˍt_t_ + _t111_C1ˍtt_t_ + _t111_C1ˍt_t_*_tpke_ - 0.7915942754515536_t111_C2ˍt_t_*_tpk21_,
    0.42185583802357607_t111_C1ˍtt_t_ + _t111_C1ˍttt_t_ + _t111_C1ˍtt_t_*_tpke_ - 0.7915942754515536_t111_C2ˍtt_t_*_tpk21_,
    -0.5329192631957003_t111_C1_t_ + _t111_C2ˍt_t_ + _t111_C2_t_*_tpk21_,
    -0.5329192631957003_t111_C1ˍt_t_ + _t111_C2ˍtt_t_ + _t111_C2ˍt_t_*_tpk21_
]

