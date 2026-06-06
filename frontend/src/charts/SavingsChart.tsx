import React from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

interface SavingsDataPoint {
  month: string;
  zaoszczedzone: number;
}

interface SavingsChartProps {
  data: SavingsDataPoint[];
  onMonthClick?: (month: string) => void;
}

export default function SavingsChart({ data, onMonthClick }: SavingsChartProps) {
  if (!data || data.length === 0) {
    return (
      <div className="flex items-center justify-center h-[300px] border border-slate-800 rounded-xl bg-slate-900/40 text-slate-500 text-sm">
        Not enough data to display chart
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={300}>
      <BarChart
        data={data}
        onClick={(state) => {
          if (state?.activeLabel && onMonthClick) {
            onMonthClick(state.activeLabel);
          }
        }}
        margin={{ top: 5, right: 20, bottom: 5, left: 0 }}
      >
        <CartesianGrid stroke="#334155" strokeDasharray="3 3" />
        <XAxis dataKey="month" stroke="#94a3b8" />
        <YAxis stroke="#94a3b8" />
        <Tooltip
          contentStyle={{
            backgroundColor: '#0f172a',
            borderColor: '#334155',
            color: '#f8fafc',
          }}
        />
        <Bar dataKey="zaoszczedzone" fill="#22c55e" name="Zaoszczędzone" radius={[4, 4, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
}
