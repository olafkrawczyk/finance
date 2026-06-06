/**
 * Simple OLS linear regression — no external library required.
 * Computes β₁ (slope) and β₀ (intercept) for y = β₀ + β₁x.
 * Uses all historical data points for prediction per D-02.
 */

export interface Point { x: number; y: number }

export function linearRegression(points: Point[]): { slope: number; intercept: number; r2: number } {
  const n = points.length;
  if (n < 2) return { slope: 0, intercept: 0, r2: 0 };

  let sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;
  for (const p of points) {
    sumX += p.x;
    sumY += p.y;
    sumXY += p.x * p.y;
    sumX2 += p.x * p.x;
    sumY2 += p.y * p.y;
  }

  const slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  const intercept = (sumY - slope * sumX) / n;

  // R-squared
  const yMean = sumY / n;
  let ssRes = 0, ssTot = 0;
  for (const p of points) {
    const predicted = slope * p.x + intercept;
    ssRes += (p.y - predicted) ** 2;
    ssTot += (p.y - yMean) ** 2;
  }
  const r2 = ssTot === 0 ? 0 : 1 - ssRes / ssTot;

  return { slope, intercept, r2 };
}

export function predictPoints(
  historicalData: { monthIndex: number; value: number }[],
  monthsToPredict: number
): { monthIndex: number; value: number }[] {
  const { slope, intercept } = linearRegression(
    historicalData.map(d => ({ x: d.monthIndex, y: d.value }))
  );
  const lastIndex = historicalData[historicalData.length - 1].monthIndex;
  return Array.from({ length: monthsToPredict }, (_, i) => ({
    monthIndex: lastIndex + i + 1,
    value: slope * (lastIndex + i + 1) + intercept,
  }));
}
