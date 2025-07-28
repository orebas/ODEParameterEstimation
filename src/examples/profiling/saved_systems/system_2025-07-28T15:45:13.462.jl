# Polynomial system saved on 2025-07-28T15:45:13.475
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:45:13.462
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t134_x1_t_
_t134_x2_t_
_t134_x1ˍt_t_
_t134_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t134_x1_t_ _t134_x2_t_ _t134_x1ˍt_t_ _t134_x2ˍt_t_
varlist = [_tpa__tpb__t134_x1_t__t134_x2_t__t134_x1ˍt_t__t134_x2ˍt_t_]

# Polynomial System
poly_system = [
    5.139861882642608 + 3.0_t134_x1_t_ - 0.25_t134_x2_t_,
    0.5533375301137464 + 3.0_t134_x1ˍt_t_ - 0.25_t134_x2ˍt_t_,
    2.9356185066351603 + 2.0_t134_x1_t_ + 0.5_t134_x2_t_,
    1.2499145697583873 + 2.0_t134_x1ˍt_t_ + 0.5_t134_x2ˍt_t_,
    _t134_x1ˍt_t_ + _t134_x2_t_*_tpa_,
    _t134_x2ˍt_t_ - _t134_x1_t_*_tpb_
]

