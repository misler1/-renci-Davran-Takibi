import { useAuth } from "@/hooks/use-auth";
import { useStudents } from "@/hooks/use-students";
import { Sidebar } from "@/components/layout/sidebar";
import { PageHeader } from "@/components/layout/page-header";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { Search, ChevronRight } from "lucide-react";
import { useState } from "react";
import { Link } from "wouter";

export default function Students() {
  const { user } = useAuth();
  const { data: students, isLoading } = useStudents();
  const [search, setSearch] = useState("");

  if (!user) return null;

  const filteredStudents = students?.filter(s => 
    s.fullName.toLowerCase().includes(search.toLowerCase()) || 
    s.studentNumber.includes(search) ||
    s.className.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 lg:ml-72 p-4 md:p-8 pt-20 lg:pt-8">
        <PageHeader 
          title="Students" 
          description="Manage student profiles and behavior records."
        />

        <div className="mb-8">
          <div className="relative max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
            <Input 
              placeholder="Search by name, ID, or class..." 
              className="pl-10 h-12 rounded-xl border-slate-200 bg-white shadow-sm"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {isLoading ? (
            // Skeletons
            Array(8).fill(0).map((_, i) => (
              <div key={i} className="h-48 bg-slate-200 rounded-2xl animate-pulse" />
            ))
          ) : filteredStudents?.map((student) => (
            <Link key={student.id} href={`/students/${student.id}`}>
              <Card className="group cursor-pointer hover:shadow-xl hover:-translate-y-1 transition-all duration-300 rounded-2xl border-slate-100 overflow-hidden bg-white">
                <div className="p-6">
                  <div className="flex justify-between items-start mb-4">
                    <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-100 to-indigo-100 text-blue-600 flex items-center justify-center font-bold text-lg">
                      {student.fullName.charAt(0)}
                    </div>
                    <span className="px-3 py-1 rounded-full bg-slate-100 text-slate-600 text-xs font-bold uppercase tracking-wider">
                      {student.className}
                    </span>
                  </div>
                  
                  <h3 className="text-lg font-bold font-display text-slate-900 mb-1 group-hover:text-blue-600 transition-colors">
                    {student.fullName}
                  </h3>
                  <p className="text-sm text-slate-500 mb-4">ID: {student.studentNumber}</p>
                  
                  <div className="pt-4 border-t border-slate-50 flex justify-between items-center text-sm text-slate-400">
                    <span>View Profile</span>
                    <ChevronRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                  </div>
                </div>
              </Card>
            </Link>
          ))}
          
          {!isLoading && filteredStudents?.length === 0 && (
            <div className="col-span-full text-center py-12">
              <p className="text-slate-400">No students found matching your search.</p>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
