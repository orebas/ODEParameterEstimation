"""Independently evaluate HC endpoints in the original, full Fujita equation pool."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path

import numpy as np
import sympy as sp


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pool', type=Path)
    parser.add_argument('run', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    pool = json.loads(args.pool.read_text())
    fixture = json.loads((args.run / 'input.json').read_text())
    result = json.loads((args.run / 'result.json').read_text())
    digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    assert digest(args.pool) == fixture['source_sha256']
    assert digest(args.run / 'input.json') == result['input_sha256']
    symbols = {name: sp.Symbol(name) for name in pool['variables']}
    equations = [sp.sympify(e.replace('^', '**').replace('//', '/'), locals=symbols)
                 for e in pool['equations']]
    evaluate = sp.lambdify(list(symbols.values()), equations, modules='numpy', cse=True)
    physical = np.asarray(fixture['physical_indices'], dtype=int) - 1
    rows = []
    for trial in result['trials']:
        target = next(c for c in fixture['cases'] if c['name'] == trial['target'])
        expected = np.asarray(target['root'])
        errors, residuals, roots = [], [], []
        for candidate in trial['candidates']:
            root = np.asarray(candidate['root_real']) + 1j * np.asarray(candidate['root_imag'])
            values = dict(zip(fixture['unknowns'], root))
            values.update(zip(fixture['all_data_variables'], target['all_data']))
            residual = float(np.max(np.abs(evaluate(*(values[n] for n in symbols)))))
            error = float(np.max(np.abs(root[physical] - expected[physical]) / np.abs(expected[physical])))
            assert np.isclose(error, candidate['max_physical_relative_error'], rtol=1e-12, atol=1e-14)
            residuals.append(residual)
            errors.append(error)
            roots.append(root)
        # Independently check separation in relative coordinate distance. This
        # verifies numerical distinctness, not certified disjoint root enclosures.
        separation = min((float(np.max(np.abs(a-b) / np.maximum(1, np.maximum(np.abs(a), np.abs(b)))))
                          for i, a in enumerate(roots) for b in roots[i+1:]), default=None)
        if separation is not None:
            assert separation > 1e-7
        best = int(np.argmin(errors)) if errors else None
        row = {'mode': trial['mode'], 'target': trial['target'], 'finite_roots': len(roots),
               'path_return_codes': dict(Counter(p['return_code'] for p in trial['paths'])),
               'min_pairwise_relative_coordinate_distance': separation,
               'full_pool_residual_below_1e_7': sum(r < 1e-7 for r in residuals),
               'best_physical_relative_error': errors[best] if best is not None else None,
               'best_root_full_pool_residual_inf': residuals[best] if best is not None else None}
        rows.append(row)
    # Nearby recovery is a required diagnostic check. In discovery mode, the
    # independent distant target must also be found; single-seed tracking need not.
    expected_targets = {'nearby', 'distant'} if 'monodromy' in result else {'nearby'}
    for name in expected_targets:
        matching = [r for r in rows if r['target'] == name]
        assert any(r['best_physical_relative_error'] is not None and
                   r['best_physical_relative_error'] < 1e-8 and
                   r['best_root_full_pool_residual_inf'] < 1e-7 for r in matching)
    output = {'source_sha256': digest(args.pool), 'input_sha256': digest(args.run / 'input.json'),
              'result_sha256': digest(args.run / 'result.json'),
              'evaluator': 'SymPy/NumPy, original full 88-equation pool',
              'scope': 'Independent endpoint checks; numerical distinctness is not a completeness certificate.',
              'trials': rows}
    args.output.write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps(rows, indent=2))


if __name__ == '__main__':
    main()
