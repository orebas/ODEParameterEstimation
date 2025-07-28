# Polynomial system saved on 2025-07-28T15:08:58.958
using Symbolics
using StaticArrays

# Metadata
# num_variables: 22
# timestamp: 2025-07-28T15:08:58.958
# num_equations: 22

# Variables
varlist_str = """
_tpa_
_tpb_
_t111_x1_t_
_t111_x2_t_
_t111_x3_t_
_t111_x3ˍt_t_
_t111_x3ˍtt_t_
_t111_x3ˍttt_t_
_t111_x1ˍt_t_
_t111_x2ˍt_t_
_t111_x1ˍtt_t_
_t111_x2ˍtt_t_
_t278_x1_t_
_t278_x2_t_
_t278_x3_t_
_t278_x3ˍt_t_
_t278_x3ˍtt_t_
_t278_x3ˍttt_t_
_t278_x1ˍt_t_
_t278_x2ˍt_t_
_t278_x1ˍtt_t_
_t278_x2ˍtt_t_
"""
@variables _tpa_ _tpb_ _t111_x1_t_ _t111_x2_t_ _t111_x3_t_ _t111_x3ˍt_t_ _t111_x3ˍtt_t_ _t111_x3ˍttt_t_ _t111_x1ˍt_t_ _t111_x2ˍt_t_ _t111_x1ˍtt_t_ _t111_x2ˍtt_t_ _t278_x1_t_ _t278_x2_t_ _t278_x3_t_ _t278_x3ˍt_t_ _t278_x3ˍtt_t_ _t278_x3ˍttt_t_ _t278_x1ˍt_t_ _t278_x2ˍt_t_ _t278_x1ˍtt_t_ _t278_x2ˍtt_t_
varlist = [_tpa__tpb__t111_x1_t__t111_x2_t__t111_x3_t__t111_x3ˍt_t__t111_x3ˍtt_t__t111_x3ˍttt_t__t111_x1ˍt_t__t111_x2ˍt_t__t111_x1ˍtt_t__t111_x2ˍtt_t__t278_x1_t__t278_x2_t__t278_x3_t__t278_x3ˍt_t__t278_x3ˍtt_t__t278_x3ˍttt_t__t278_x1ˍt_t__t278_x2ˍt_t__t278_x1ˍtt_t__t278_x2ˍtt_t_]

# Polynomial System
poly_system = [
    -5.732340409784948 + _t111_x3_t_,
    -1.6589697586348306 + _t111_x3ˍt_t_,
    -0.17054474263612812 + _t111_x3ˍtt_t_,
    -0.05022613413210782 + _t111_x3ˍttt_t_,
    -0.9061822298232436(_t111_x1_t_ + _t111_x2_t_) + _t111_x3ˍt_t_,
    -0.9061822298232436(_t111_x1ˍt_t_ + _t111_x2ˍt_t_) + _t111_x3ˍtt_t_,
    -0.9061822298232436(_t111_x1ˍtt_t_ + _t111_x2ˍtt_t_) + _t111_x3ˍttt_t_,
    _t111_x1ˍt_t_ + _t111_x1_t_*_tpa_,
    _t111_x2ˍt_t_ - _t111_x2_t_*_tpb_,
    _t111_x1ˍtt_t_ + _t111_x1ˍt_t_*_tpa_,
    _t111_x2ˍtt_t_ - _t111_x2ˍt_t_*_tpb_,
    -8.782572688435053 + _t278_x3_t_,
    -2.021012740797323 + _t278_x3ˍt_t_,
    -0.26775149503322815 + _t278_x3ˍtt_t_,
    -0.06719245252634118 + _t278_x3ˍttt_t_,
    -0.9061822298232436(_t278_x1_t_ + _t278_x2_t_) + _t278_x3ˍt_t_,
    -0.9061822298232436(_t278_x1ˍt_t_ + _t278_x2ˍt_t_) + _t278_x3ˍtt_t_,
    -0.9061822298232436(_t278_x1ˍtt_t_ + _t278_x2ˍtt_t_) + _t278_x3ˍttt_t_,
    _t278_x1ˍt_t_ + _t278_x1_t_*_tpa_,
    _t278_x2ˍt_t_ - _t278_x2_t_*_tpb_,
    _t278_x1ˍtt_t_ + _t278_x1ˍt_t_*_tpa_,
    _t278_x2ˍtt_t_ - _t278_x2ˍt_t_*_tpb_
]

