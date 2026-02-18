import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@shared/routes";
import { useToast } from "@/hooks/use-toast";
import { apiUrl } from "@/lib/api-base";
import { z } from "zod";

type CreateBehaviorRequest = z.infer<typeof api.behaviors.create.input>;

export function useBehaviors(filters?: { studentId?: string; teacherId?: string }) {
  // Create a stable key based on filters
  const queryKey = [api.behaviors.list.path, filters?.studentId, filters?.teacherId].filter(Boolean);

  return useQuery({
    queryKey,
    queryFn: async () => {
      // Build query string manually or use URLSearchParams
      const url = new URL(apiUrl(api.behaviors.list.path), window.location.origin);
      if (filters?.studentId) url.searchParams.append("studentId", filters.studentId);
      if (filters?.teacherId) url.searchParams.append("teacherId", filters.teacherId);
      
      const res = await fetch(url.toString(), { credentials: "include" });
      if (!res.ok) throw new Error("Failed to fetch behaviors");
      return api.behaviors.list.responses[200].parse(await res.json());
    },
  });
}

export function useBehaviorStats() {
  return useQuery({
    queryKey: [api.behaviors.stats.path],
    queryFn: async () => {
      const res = await fetch(apiUrl(api.behaviors.stats.path), {
        credentials: "include",
      });
      if (!res.ok) throw new Error("Failed to fetch stats");
      return api.behaviors.stats.responses[200].parse(await res.json());
    },
  });
}

export function useCreateBehavior() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  return useMutation({
    mutationFn: async (data: CreateBehaviorRequest) => {
      const res = await fetch(apiUrl(api.behaviors.create.path), {
        method: api.behaviors.create.method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
        credentials: "include",
      });

      if (!res.ok) throw new Error("Failed to record behavior");
      return api.behaviors.create.responses[201].parse(await res.json());
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [api.behaviors.list.path] });
      queryClient.invalidateQueries({ queryKey: [api.behaviors.stats.path] });
      toast({
        title: "Success",
        description: "Behavior recorded successfully",
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
