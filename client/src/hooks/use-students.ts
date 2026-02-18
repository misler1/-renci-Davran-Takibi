import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api, buildUrl } from "@shared/routes";
import { useToast } from "@/hooks/use-toast";
import { apiUrl } from "@/lib/api-base";
import { z } from "zod";

type InsertStudent = z.infer<typeof api.students.create.input>;

export function useStudents() {
  return useQuery({
    queryKey: [api.students.list.path],
    queryFn: async () => {
      const res = await fetch(apiUrl(api.students.list.path), {
        credentials: "include",
      });
      if (!res.ok) throw new Error("Failed to fetch students");
      return api.students.list.responses[200].parse(await res.json());
    },
  });
}

export function useStudent(id: number) {
  return useQuery({
    queryKey: [api.students.get.path, id],
    queryFn: async () => {
      const url = buildUrl(api.students.get.path, { id });
      const res = await fetch(apiUrl(url), {
        credentials: "include",
      });
      if (!res.ok) throw new Error("Failed to fetch student");
      return api.students.get.responses[200].parse(await res.json());
    },
    enabled: !!id,
  });
}

export function useCreateStudent() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  return useMutation({
    mutationFn: async (data: InsertStudent) => {
      const res = await fetch(apiUrl(api.students.create.path), {
        method: api.students.create.method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
        credentials: "include",
      });

      if (!res.ok) throw new Error("Failed to create student");
      return api.students.create.responses[201].parse(await res.json());
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [api.students.list.path] });
      toast({
        title: "Success",
        description: "Student created successfully",
      });
    },
    onError: (error: Error) => {
      toast({
        title: "Error",
        description: error.message,
        variant: "destructive",
      });
    },
  });
}
