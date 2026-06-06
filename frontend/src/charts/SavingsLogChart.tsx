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

interface SavingsLogDataPoint {
  month: string;
  zaoszczedzone_log: number;
}

interface SavingsLogChartProps {
  data: SavingsLogDataPoint[];
  onMonthClick?: (month: string) => void;
}

export default function SavingsLogChart({ data, onMonthClick }: SavingsLogChartProps) {
  const formatLog = (val: number) => val.toFixed(2);

  if (!data || data.length < 2) {
    return (
      <div className="flex items-center justify-center h-[300px] border border-slate-800 rounded-xl bg-slate-900/40 text-slate-500 text-sm">
        Not enough data to display chart
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart
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
        <YAxis stroke="#94a3b8" tickFormatter={formatLog} />
        <Tooltip
          contentStyle={{
            backgroundColor: '#0f172a',
            borderColor: '#334155',
            color: '#f8fafc',
          }}
          formatter={(value: any, name: any) => [formatLog(Number(value)), name]}
        />
        <Line
          type="monotone"
          dataKey="zaoszczedzone_log"
          stroke="#a855f7"
          strokeWidth={2}
          name="Zaoszcz. log"
          activeDot={{ r: 6 }}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}
