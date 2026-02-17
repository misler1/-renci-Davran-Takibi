import { useAuth } from "@/hooks/use-auth";
import { useStudent } from "@/hooks/use-students";
import { useBehaviors } from "@/hooks/use-behaviors";
import { Sidebar } from "@/components/layout/sidebar";
import { PageHeader } from "@/components/layout/page-header";
import { Card, CardContent } from "@/components/ui/card";
import { BehaviorDialog } from "@/components/behavior-dialog";
import { useRoute } from "wouter";
import { 
  User, 
  Phone, 
  Users, 
  Clock, 
  CheckCircle2, 
  AlertCircle 
} from "lucide-react";
import { format } from "date-fns";
import { cn } from "@/lib/utils";

export default function StudentDetail() {
  const { user } = useAuth();
  const [, params] = useRoute("/students/:id");
  const studentId = Number(params?.id);
  
  const { data: student, isLoading: loadingStudent } = useStudent(studentId);
  const { data: behaviors, isLoading: loadingBehaviors } = useBehaviors({ studentId: String(studentId) });

  if (!user) return null;
  if (loadingStudent) return null; // Or a nice spinner
  if (!student) return <div>Student not found</div>;

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 lg:ml-72 p-4 md:p-8 pt-20 lg:pt-8">
        <PageHeader 
          title={student.fullName}
          description={`Class ${student.className} • ID: ${student.studentNumber}`}
        >
          <BehaviorDialog currentUserId={user.id} defaultStudentId={student.id} />
        </PageHeader>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column: Student Info */}
          <div className="space-y-6">
            <Card className="rounded-2xl border-slate-100 bg-white overflow-hidden shadow-sm">
              <div className="h-24 bg-gradient-to-r from-blue-500 to-indigo-500" />
              <div className="px-6 pb-6 relative">
                <div className="w-20 h-20 bg-white rounded-full p-1 absolute -top-10 shadow-lg">
                  <div className="w-full h-full bg-slate-100 rounded-full flex items-center justify-center text-2xl font-bold text-slate-400">
                    {student.fullName.charAt(0)}
                  </div>
                </div>
                
                <div className="mt-12 space-y-4">
                  <div className="flex items-center gap-3 text-slate-600">
                    <User className="w-5 h-5 text-slate-400" />
                    <span className="font-medium">{student.parentName || "No parent info"}</span>
                  </div>
                  <div className="flex items-center gap-3 text-slate-600">
                    <Phone className="w-5 h-5 text-slate-400" />
                    <span className="font-medium">{student.parentPhone || "No phone info"}</span>
                  </div>
                  <div className="flex items-center gap-3 text-slate-600">
                    <Users className="w-5 h-5 text-slate-400" />
                    <span className="font-medium">Coach: Not assigned</span>
                  </div>
                </div>
              </div>
            </Card>

            <div className="bg-blue-50 rounded-2xl p-6 border border-blue-100">
              <h3 className="text-blue-900 font-bold mb-2">Behavior Summary</h3>
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-white p-4 rounded-xl shadow-sm border border-blue-100 text-center">
                  <div className="text-2xl font-bold text-green-600">
                    {behaviors?.filter(b => b.type === 'positive').length || 0}
                  </div>
                  <div className="text-xs text-slate-500 uppercase font-bold tracking-wider">Positive</div>
                </div>
                <div className="bg-white p-4 rounded-xl shadow-sm border border-blue-100 text-center">
                  <div className="text-2xl font-bold text-red-600">
                    {behaviors?.filter(b => b.type === 'negative').length || 0}
                  </div>
                  <div className="text-xs text-slate-500 uppercase font-bold tracking-wider">Negative</div>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column: Timeline */}
          <div className="lg:col-span-2">
            <h2 className="text-xl font-bold font-display text-slate-900 mb-6 flex items-center gap-2">
              <Clock className="w-5 h-5 text-slate-400" />
              History
            </h2>

            <div className="relative border-l-2 border-slate-200 ml-3 space-y-8 pl-8 pb-8">
              {behaviors?.map((record) => (
                <div key={record.id} className="relative">
                  {/* Timeline Dot */}
                  <div className={cn(
                    "absolute -left-[41px] top-2 w-6 h-6 rounded-full border-4 border-white shadow-sm",
                    record.type === 'positive' ? "bg-green-500" : "bg-red-500"
                  )} />

                  <Card className="rounded-xl border-slate-100 bg-white hover:shadow-md transition-shadow">
                    <div className="p-5">
                      <div className="flex justify-between items-start mb-2">
                        <div className="flex items-center gap-2">
                          <span className={cn(
                            "px-2.5 py-0.5 rounded-full text-xs font-bold uppercase tracking-wider",
                            record.type === 'positive' 
                              ? "bg-green-100 text-green-700" 
                              : "bg-red-100 text-red-700"
                          )}>
                            {record.category}
                          </span>
                          {record.type === 'positive' 
                            ? <CheckCircle2 className="w-4 h-4 text-green-500" />
                            : <AlertCircle className="w-4 h-4 text-red-500" />
                          }
                        </div>
                        <span className="text-xs text-slate-400 font-medium">
                          {format(new Date(record.date), 'PP p')}
                        </span>
                      </div>
                      
                      <p className="text-slate-700 mb-3">{record.description}</p>
                      
                      <div className="flex items-center gap-2 text-xs text-slate-400 border-t border-slate-50 pt-3">
                        <div className="w-5 h-5 rounded-full bg-slate-200 flex items-center justify-center text-[10px] font-bold text-slate-500">
                          {record.teacher?.fullName.charAt(0)}
                        </div>
                        Recorded by {record.teacher?.fullName}
                      </div>
                    </div>
                  </Card>
                </div>
              ))}
              
              {behaviors?.length === 0 && (
                <div className="text-slate-400 italic">No records found for this student.</div>
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
