import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { useCreateBehavior } from "@/hooks/use-behaviors";
import { useStudents } from "@/hooks/use-students";
import { insertBehaviorSchema } from "@shared/schema";
import { Plus, Loader2 } from "lucide-react";
import { useState } from "react";

const formSchema = insertBehaviorSchema.extend({
  notifyClassTeacher: z.boolean().default(false),
  notifyCoach: z.boolean().default(false),
  studentId: z.coerce.number(), // Coerce from string select value
  stage: z.coerce.number().default(1),
  teacherId: z.number(), // Will be injected from current user
});

type FormValues = z.infer<typeof formSchema>;

export function BehaviorDialog({ triggerButton, defaultStudentId, currentUserId }: { 
  triggerButton?: React.ReactNode, 
  defaultStudentId?: number,
  currentUserId: number 
}) {
  const [open, setOpen] = useState(false);
  const { mutate, isPending } = useCreateBehavior();
  const { data: students, isLoading: isLoadingStudents } = useStudents();

  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      studentId: defaultStudentId || 0,
      teacherId: currentUserId,
      type: "positive",
      category: "",
      description: "",
      stage: 1,
      notifyClassTeacher: false,
      notifyCoach: false,
    },
  });

  function onSubmit(data: FormValues) {
    mutate(data, {
      onSuccess: () => {
        setOpen(false);
        form.reset();
      },
    });
  }

  const selectedType = form.watch("type");

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {triggerButton || (
          <Button className="shadow-lg shadow-primary/20 hover:shadow-primary/40 transition-all">
            <Plus className="w-4 h-4 mr-2" />
            Add Behavior
          </Button>
        )}
      </DialogTrigger>
      <DialogContent className="sm:max-w-[500px] rounded-2xl">
        <DialogHeader>
          <DialogTitle className="text-2xl font-display font-bold">Record Behavior</DialogTitle>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6 mt-4">
            
            {!defaultStudentId && (
              <FormField
                control={form.control}
                name="studentId"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Student</FormLabel>
                    <Select 
                      onValueChange={field.onChange} 
                      defaultValue={field.value ? String(field.value) : undefined}
                      disabled={isLoadingStudents}
                    >
                      <FormControl>
                        <SelectTrigger className="h-12 rounded-xl">
                          <SelectValue placeholder="Select a student" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {students?.map((s) => (
                          <SelectItem key={s.id} value={String(s.id)}>
                            {s.fullName} ({s.className})
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
            )}

            <div className="grid grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="type"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Type</FormLabel>
                    <Select onValueChange={field.onChange} defaultValue={field.value}>
                      <FormControl>
                        <SelectTrigger className="h-12 rounded-xl">
                          <SelectValue placeholder="Select Type" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        <SelectItem value="positive">Positive</SelectItem>
                        <SelectItem value="negative">Negative</SelectItem>
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="category"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Category</FormLabel>
                    <Select onValueChange={field.onChange} defaultValue={field.value}>
                      <FormControl>
                        <SelectTrigger className="h-12 rounded-xl">
                          <SelectValue placeholder="Category" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {selectedType === "positive" ? (
                          <>
                            <SelectItem value="Participation">Participation</SelectItem>
                            <SelectItem value="Leadership">Leadership</SelectItem>
                            <SelectItem value="Helpfulness">Helpfulness</SelectItem>
                            <SelectItem value="Improvement">Improvement</SelectItem>
                          </>
                        ) : (
                          <>
                            <SelectItem value="Late">Late Arrival</SelectItem>
                            <SelectItem value="Disruption">Disruption</SelectItem>
                            <SelectItem value="Homework">Missing Homework</SelectItem>
                            <SelectItem value="Disrespect">Disrespect</SelectItem>
                            <SelectItem value="Uniform">Uniform Violation</SelectItem>
                          </>
                        )}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            <FormField
              control={form.control}
              name="description"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Description</FormLabel>
                  <FormControl>
                    <Textarea 
                      placeholder="Add specific details about the behavior..." 
                      className="resize-none min-h-[100px] rounded-xl"
                      {...field} 
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            {selectedType === "negative" && (
              <div className="flex flex-col gap-3 p-4 bg-muted/50 rounded-xl border border-border/50">
                <h4 className="font-semibold text-sm text-muted-foreground mb-1">Notifications</h4>
                <FormField
                  control={form.control}
                  name="notifyClassTeacher"
                  render={({ field }) => (
                    <FormItem className="flex flex-row items-start space-x-3 space-y-0">
                      <FormControl>
                        <Checkbox
                          checked={field.value}
                          onCheckedChange={field.onChange}
                        />
                      </FormControl>
                      <div className="space-y-1 leading-none">
                        <FormLabel>Notify Class Teacher</FormLabel>
                      </div>
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="notifyCoach"
                  render={({ field }) => (
                    <FormItem className="flex flex-row items-start space-x-3 space-y-0">
                      <FormControl>
                        <Checkbox
                          checked={field.value}
                          onCheckedChange={field.onChange}
                        />
                      </FormControl>
                      <div className="space-y-1 leading-none">
                        <FormLabel>Notify Coach</FormLabel>
                      </div>
                    </FormItem>
                  )}
                />
              </div>
            )}

            <div className="flex justify-end gap-3 pt-4">
              <Button type="button" variant="outline" onClick={() => setOpen(false)} className="rounded-xl">Cancel</Button>
              <Button type="submit" disabled={isPending} className="rounded-xl px-6">
                {isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                Save Record
              </Button>
            </div>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}
