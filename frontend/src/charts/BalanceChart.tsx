import React from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

interface BalanceDataPoint {
  month: string;
  stan_konta: number | null;
}

interface BalanceChartProps {
  data: BalanceDataPoint[];
  onMonthClick?: (month: string) => void;
}

export default function BalanceChart({ data, onMonthClick }: BalanceChartProps) {
  const filteredData = data.filter((d) => d.stan_konta !== null);

  const formatCurrency = (val: number) =>
    new Intl.NumberFormat('pl-PL', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(val);

  const formatYAxis = (val: number) =>
    new Intl.NumberFormat('pl-PL', {
      maximumFractionDigits: 0,
    }).format(val);

  if (filteredData.length < 2) {
    return (
      <div className="flex items-center justify-center h-[300px] border border-slate-800 rounded-xl bg-slate-900/40 text-slate-500 text-sm">
        Not enough data to display chart
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart
        data={filteredData}
        onClick={(state) => {
          if (state?.activeLabel && onMonthClick) {
            onMonthClick(state.activeLabel);
          }
        }}
        margin={{ top: 5, right: 20, bottom: 5, left: 0 }}
      >
        <CartesianGrid stroke="#334155" strokeDasharray="3 3" />
        <XAxis dataKey="month" stroke="#94a3b8" />
        <YAxis stroke="#94a3b8" tickFormatter={formatYAxis} />
        <Tooltip
          contentStyle={{
            backgroundColor: '#0f172a',
            borderColor: '#334155',
            color: '#f8fafc',
          }}
          formatter={(value: any, name: any) => [formatCurrency(Number(value)), name]}
        />
        <Line
          type="monotone"
          dataKey="stan_konta"
          stroke="#3b82f6"
          strokeWidth={2}
          name="Stan konta"
          activeDot={{ r: 6 }}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}
