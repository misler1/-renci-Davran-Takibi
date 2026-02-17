import { useAuth } from "@/hooks/use-auth";
import { Sidebar } from "@/components/layout/sidebar";
import { PageHeader } from "@/components/layout/page-header";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Search, UserPlus, MessageSquare, Mail, Phone, GraduationCap, Archive, Trash2, Edit } from "lucide-react";
import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { api, buildUrl } from "@shared/routes";
import { queryClient } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
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
import { insertUserSchema, type User } from "@shared/schema";
import { Link } from "wouter";

export default function Teachers() {
  const { user: currentUser } = useAuth();
  const { toast } = useToast();
  const [search, setSearch] = useState("");
  const [showArchived, setShowArchived] = useState(false);

  const { data: teachers, isLoading } = useQuery<User[]>({
    queryKey: [api.users.list.path],
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: number) => {
      const res = await fetch(buildUrl(api.users.delete.path, { id }), {
        method: "DELETE",
      });
      if (!res.ok) throw new Error("Failed to delete");
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [api.users.list.path] });
      toast({ title: "Success", description: "Teacher deleted successfully" });
    },
  });

  const archiveMutation = useMutation({
    mutationFn: async ({ id, status }: { id: number; status: string }) => {
      const res = await fetch(buildUrl(api.users.update.path, { id }), {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status }),
      });
      if (!res.ok) throw new Error("Failed to update status");
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [api.users.list.path] });
      toast({ title: "Success", description: "Teacher status updated" });
    },
  });

  const createMutation = useMutation({
    mutationFn: async (data: any) => {
      const res = await fetch(api.users.create.path, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      if (!res.ok) throw new Error("Failed to create teacher");
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [api.users.list.path] });
      toast({ title: "Success", description: "Teacher added successfully" });
    },
  });

  const form = useForm({
    resolver: zodResolver(insertUserSchema),
    defaultValues: {
      username: "",
      password: "P123456",
      fullName: "",
      email: "",
      role: "teacher",
      classTeacherOf: "",
      coachGroup: "",
    },
  });

  if (!currentUser) return null;

  const filteredTeachers = teachers?.filter(t => {
    const matchesSearch = t.fullName.toLowerCase().includes(search.toLowerCase()) || 
                         t.username.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = showArchived ? true : t.status === 'active';
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 lg:ml-72 p-4 md:p-8 pt-20 lg:pt-8">
        <PageHeader 
          title="Teachers" 
          description="Manage school staff and roles."
        >
          <Dialog>
            <DialogTrigger asChild>
              <Button className="rounded-xl shadow-lg shadow-blue-200">
                <UserPlus className="w-4 h-4 mr-2" />
                Add Teacher
              </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[425px] rounded-2xl">
              <DialogHeader>
                <DialogTitle>Add New Teacher</DialogTitle>
              </DialogHeader>
              <Form {...form}>
                <form onSubmit={form.handleSubmit((data) => createMutation.mutate(data))} className="space-y-4">
                  <FormField
                    control={form.control}
                    name="fullName"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Full Name</FormLabel>
                        <FormControl><Input {...field} placeholder="John Doe" /></FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="username"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Username</FormLabel>
                        <FormControl><Input {...field} placeholder="john.doe" /></FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="email"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Email</FormLabel>
                        <FormControl><Input {...field} type="email" placeholder="john@school.com" /></FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <DialogFooter>
                    <Button type="submit" disabled={createMutation.isPending}>Add Teacher</Button>
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
              placeholder="Search teachers..." 
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

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {isLoading ? (
            Array(6).fill(0).map((_, i) => (
              <div key={i} className="h-48 bg-slate-200 rounded-2xl animate-pulse" />
            ))
          ) : filteredTeachers?.map((teacher) => (
            <Card key={teacher.id} className={cn(
              "rounded-2xl border-slate-100 overflow-hidden bg-white shadow-sm hover:shadow-md transition-all",
              teacher.status === 'archived' && "opacity-60 grayscale"
            )}>
              <CardContent className="p-6">
                <div className="flex justify-between items-start mb-4">
                  <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-indigo-500 to-blue-500 flex items-center justify-center text-white font-bold text-xl shadow-lg">
                    {teacher.fullName.charAt(0)}
                  </div>
                  <div className="flex gap-1">
                    <Button 
                      variant="ghost" 
                      size="icon" 
                      className="h-8 w-8 text-slate-400 hover:text-blue-600"
                      onClick={() => archiveMutation.mutate({ id: teacher.id, status: teacher.status === 'active' ? 'archived' : 'active' })}
                    >
                      <Archive className="h-4 w-4" />
                    </Button>
                    <Button 
                      variant="ghost" 
                      size="icon" 
                      className="h-8 w-8 text-slate-400 hover:text-red-600"
                      onClick={() => deleteMutation.mutate(teacher.id)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>

                <h3 className="text-lg font-bold text-slate-900 mb-1">{teacher.fullName}</h3>
                <p className="text-sm text-slate-500 mb-4 flex items-center gap-2">
                  <Mail className="w-3 h-3" /> {teacher.email}
                </p>

                <div className="grid grid-cols-2 gap-2 text-xs mb-4">
                  <div className="bg-slate-50 p-2 rounded-lg">
                    <p className="text-slate-400 font-bold uppercase mb-1">Class</p>
                    <p className="text-slate-700 font-semibold">{teacher.classTeacherOf || "None"}</p>
                  </div>
                  <div className="bg-slate-50 p-2 rounded-lg">
                    <p className="text-slate-400 font-bold uppercase mb-1">Role</p>
                    <p className="text-slate-700 font-semibold capitalize">{teacher.role}</p>
                  </div>
                </div>

                <div className="flex gap-2">
                  <Link href="/messages" className="flex-1">
                    <Button variant="outline" className="w-full rounded-xl gap-2 h-10 border-slate-200">
                      <MessageSquare className="w-4 h-4" />
                      Message
                    </Button>
                  </Link>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </main>
    </div>
  );
}
