interface SkeletonProps {
  className?: string;
}

export default function Skeleton({ className = 'h-4 w-full' }: SkeletonProps) {
  return (
    <div
      className={`animate-pulse bg-slate-800/50 rounded-lg ${className}`}
      aria-hidden="true"
    />
  );
}
