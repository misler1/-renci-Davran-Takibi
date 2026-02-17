import { useAuth } from "@/hooks/use-auth";
import { useBehaviorStats, useBehaviors } from "@/hooks/use-behaviors";
import { Sidebar } from "@/components/layout/sidebar";
import { PageHeader } from "@/components/layout/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { BehaviorDialog } from "@/components/behavior-dialog";
import { 
  TrendingUp, 
  TrendingDown, 
  Activity, 
  Clock, 
  AlertCircle,
  CheckCircle2
} from "lucide-react";
import { format } from "date-fns";
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from "recharts";
import { cn } from "@/lib/utils";

export default function Dashboard() {
  const { user } = useAuth();
  const { data: stats } = useBehaviorStats();
  const { data: behaviors } = useBehaviors(); // Recent behaviors

  if (!user) return null;

  const chartData = [
    { name: 'Positive', value: stats?.positive || 0, color: '#22c55e' },
    { name: 'Negative', value: stats?.negative || 0, color: '#ef4444' },
  ];

  const recentActivity = behaviors?.slice(0, 5) || [];

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 lg:ml-72 p-4 md:p-8 pt-20 lg:pt-8">
        <PageHeader 
          title="Dashboard" 
          description={`Welcome back, ${user.fullName}. Here's what's happening today.`}
        >
          <BehaviorDialog currentUserId={user.id} />
        </PageHeader>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <Card className="rounded-2xl shadow-sm border-slate-100 bg-white overflow-hidden relative group">
            <div className="absolute right-0 top-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
              <Activity className="w-24 h-24 text-blue-600" />
            </div>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-slate-500 uppercase tracking-wider">Total Records</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-4xl font-bold font-display text-slate-900">{stats?.total || 0}</div>
              <p className="text-sm text-slate-500 mt-1">Recorded this semester</p>
            </CardContent>
          </Card>

          <Card className="rounded-2xl shadow-sm border-slate-100 bg-white overflow-hidden relative group">
            <div className="absolute right-0 top-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
              <TrendingUp className="w-24 h-24 text-green-600" />
            </div>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-slate-500 uppercase tracking-wider">Positive</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-4xl font-bold font-display text-green-600">{stats?.positive || 0}</div>
              <p className="text-sm text-slate-500 mt-1">Merits and awards</p>
            </CardContent>
          </Card>

          <Card className="rounded-2xl shadow-sm border-slate-100 bg-white overflow-hidden relative group">
            <div className="absolute right-0 top-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
              <TrendingDown className="w-24 h-24 text-red-600" />
            </div>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-slate-500 uppercase tracking-wider">Negative</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-4xl font-bold font-display text-red-600">{stats?.negative || 0}</div>
              <p className="text-sm text-slate-500 mt-1">Incidents and warnings</p>
            </CardContent>
          </Card>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            <h2 className="text-xl font-bold font-display text-slate-900 flex items-center gap-2">
              <Clock className="w-5 h-5 text-slate-400" />
              Recent Activity
            </h2>
            
            <div className="space-y-4">
              {recentActivity.map((record) => (
                <Card key={record.id} className="rounded-xl border-slate-100 hover:shadow-md transition-all duration-300">
                  <div className="p-4 flex flex-col sm:flex-row gap-4 sm:items-center">
                    <div className={cn(
                      "w-12 h-12 rounded-full flex items-center justify-center shrink-0",
                      record.type === 'positive' ? "bg-green-100 text-green-600" : "bg-red-100 text-red-600"
                    )}>
                      {record.type === 'positive' ? <CheckCircle2 className="w-6 h-6" /> : <AlertCircle className="w-6 h-6" />}
                    </div>
                    
                    <div className="flex-1">
                      <div className="flex items-center justify-between mb-1">
                        <h3 className="font-semibold text-slate-900">{record.student.fullName}</h3>
                        <span className="text-xs text-slate-400 font-medium">
                          {format(new Date(record.date), 'MMM d, h:mm a')}
                        </span>
                      </div>
                      <p className="text-sm text-slate-600">
                        <span className="font-medium text-slate-800">{record.category}</span>
                        <span className="mx-2 text-slate-300">•</span>
                        {record.description}
                      </p>
                    </div>
                  </div>
                </Card>
              ))}
              
              {recentActivity.length === 0 && (
                <div className="text-center py-12 text-slate-400 bg-white rounded-xl border border-dashed border-slate-200">
                  No activity recorded yet
                </div>
              )}
            </div>
          </div>

          <div className="space-y-6">
            <h2 className="text-xl font-bold font-display text-slate-900">Statistics</h2>
            <Card className="p-6 rounded-2xl border-slate-100 flex flex-col items-center justify-center min-h-[300px]">
              <div className="w-full h-[200px]">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={chartData}
                      cx="50%"
                      cy="50%"
                      innerRadius={60}
                      outerRadius={80}
                      paddingAngle={5}
                      dataKey="value"
                    >
                      {chartData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} strokeWidth={0} />
                      ))}
                    </Pie>
                    <Tooltip 
                      contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              </div>
              <div className="flex gap-8 mt-4">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full bg-green-500" />
                  <span className="text-sm font-medium text-slate-600">Positive</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full bg-red-500" />
                  <span className="text-sm font-medium text-slate-600">Negative</span>
                </div>
              </div>
            </Card>
          </div>
        </div>
      </main>
    </div>
  );
}
