import { useAuth } from "@/hooks/use-auth";
import { useStudents } from "@/hooks/use-students";
import { Sidebar } from "@/components/layout/sidebar";
import { PageHeader } from "@/components/layout/page-header";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Search, ChevronRight, UserPlus } from "lucide-react";
import { useState } from "react";
import { Link } from "wouter";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { insertStudentSchema } from "@shared/schema";
import { useMutation } from "@tanstack/react-query";
import { api } from "@shared/routes";
import { queryClient } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";

export default function Students() {
  const { user } = useAuth();
  const { toast } = useToast();
  const { data: students, isLoading } = useStudents();
  const [search, setSearch] = useState("");
  const [showArchived, setShowArchived] = useState(false);

  const createMutation = useMutation({
    mutationFn: async (data: any) => {
      const res = await fetch(api.students.create.path, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      if (!res.ok) throw new Error("Failed to create student");
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [api.students.list.path] });
      toast({ title: "Success", description: "Student added successfully" });
    },
  });

  const form = useForm({
    resolver: zodResolver(insertStudentSchema),
    defaultValues: {
      studentNumber: "",
      fullName: "",
      className: "",
      parentName: "",
      parentPhone: "",
    },
  });

  if (!user) return null;

  const filteredStudents = students?.filter(s => {
    const matchesSearch = s.fullName.toLowerCase().includes(search.toLowerCase()) || 
                         s.studentNumber.includes(search) ||
                         s.className.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = showArchived ? true : s.status === 'active';
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 lg:ml-72 p-4 md:p-8 pt-20 lg:pt-8">
        <PageHeader 
          title="Students" 
          description="Manage student profiles and behavior records."
        >
          <Dialog>
            <DialogTrigger asChild>
              <Button className="rounded-xl shadow-lg shadow-blue-200">
                <UserPlus className="w-4 h-4 mr-2" />
                Add Student
              </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[425px] rounded-2xl">
              <DialogHeader>
                <DialogTitle>Add New Student</DialogTitle>
              </DialogHeader>
              <Form {...form}>
                <form onSubmit={form.handleSubmit((data) => createMutation.mutate(data))} className="space-y-4">
                  <FormField
                    control={form.control}
                    name="fullName"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Full Name</FormLabel>
                        <FormControl><Input {...field} placeholder="Ali Veli" /></FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <div className="grid grid-cols-2 gap-4">
                    <FormField
                      control={form.control}
                      name="studentNumber"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Student ID</FormLabel>
                          <FormControl><Input {...field} placeholder="101" /></FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                    <FormField
                      control={form.control}
                      name="className"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Class</FormLabel>
                          <FormControl><Input {...field} placeholder="9-A" /></FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                  </div>
                  <FormField
                    control={form.control}
                    name="parentName"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Parent Name</FormLabel>
                        <FormControl><Input {...field} placeholder="Parent Name" /></FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <DialogFooter>
                    <Button type="submit" disabled={createMutation.isPending}>Add Student</Button>
                  </DialogFooter>
                </form>
              </Form>
            </DialogContent>
          </Dialog>
        </PageHeader>

        <div className="flex flex-col md:flex-row gap-4 mb-8 items-center justify-between">
          <div className="relative w-full max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
            <Input 
              placeholder="Search by name, ID, or class..." 
              className="pl-10 h-12 rounded-xl border-slate-200 bg-white shadow-sm w-full"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          <Button 
            variant="ghost" 
            onClick={() => setShowArchived(!showArchived)}
            className={cn("rounded-xl", showArchived && "bg-slate-200")}
          >
            {showArchived ? "Hide Archived" : "Show Archived"}
          </Button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {isLoading ? (
            Array(8).fill(0).map((_, i) => (
              <div key={i} className="h-48 bg-slate-200 rounded-2xl animate-pulse" />
            ))
          ) : filteredStudents?.map((student) => (
            <Link key={student.id} href={`/students/${student.id}`}>
              <Card className={cn(
                "group cursor-pointer hover:shadow-xl hover:-translate-y-1 transition-all duration-300 rounded-2xl border-slate-100 overflow-hidden bg-white shadow-sm",
                student.status === 'archived' && "opacity-60 grayscale"
              )}>
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
