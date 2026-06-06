import { describe, it, expect } from 'bun:test';
import { linearRegression, predictPoints } from '../frontend/src/lib/linearRegression';

describe('linearRegression', () => {
  it('correctly calculates slope, intercept, and r2 for a perfect linear relationship', () => {
    const points = [
      { x: 0, y: 0 },
      { x: 1, y: 1 },
      { x: 2, y: 2 },
    ];
    const result = linearRegression(points);
    expect(result.slope).toBe(1);
    expect(result.intercept).toBe(0);
    expect(result.r2).toBe(1);
  });

  it('handles small datasets (fewer than 2 points) gracefully by returning zeroed metrics', () => {
    expect(linearRegression([])).toEqual({ slope: 0, intercept: 0, r2: 0 });
    expect(linearRegression([{ x: 1, y: 1 }])).toEqual({ slope: 0, intercept: 0, r2: 0 });
  });

  it('correctly predicts future points based on historical trend', () => {
    const history = [
      { monthIndex: 1, value: 10 },
      { monthIndex: 2, value: 20 },
      { monthIndex: 3, value: 30 },
    ];
    // predicts months 4 and 5
    const predictions = predictPoints(history, 2);
    expect(predictions).toHaveLength(2);
    expect(predictions[0]).toEqual({ monthIndex: 4, value: 40 });
    expect(predictions[1]).toEqual({ monthIndex: 5, value: 50 });
  });
});
