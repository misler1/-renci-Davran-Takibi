import { useAuth } from "@/hooks/use-auth";
import { Sidebar } from "@/components/layout/sidebar";
import { PageHeader } from "@/components/layout/page-header";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Send, Search, User, MessageSquare } from "lucide-react";
import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { api, buildUrl } from "@shared/routes";
import { queryClient } from "@/lib/queryClient";
import { useForm } from "react-hook-form";
import { cn } from "@/lib/utils";
import { format } from "date-fns";
import type { Message, User as Teacher } from "@shared/schema";
import { apiUrl } from "@/lib/api-base";

export default function Messages() {
  const { user: currentUser } = useAuth();
  const [selectedContact, setSelectedContact] = useState<Teacher | null>(null);
  const [messageText, setMessageText] = useState("");

  const { data: teachers } = useQuery<Teacher[]>({
    queryKey: [api.users.list.path],
  });

  const { data: messageHistory, isLoading: loadingMessages } = useQuery<Message[]>({
    queryKey: [api.messages.list.path, selectedContact?.id],
    enabled: !!selectedContact,
    queryFn: async () => {
      const res = await fetch(
        apiUrl(`${api.messages.list.path}?contactId=${selectedContact?.id}`),
        { credentials: "include" },
      );
      if (!res.ok) throw new Error("Failed to fetch messages");
      return res.json();
    },
    refetchInterval: 3000,
  });

  const sendMutation = useMutation({
    mutationFn: async (content: string) => {
      if (!selectedContact || !currentUser) return;
      const res = await fetch(apiUrl(api.messages.send.path), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          senderId: currentUser.id,
          recipientId: selectedContact.id,
          content,
        }),
        credentials: "include",
      });
      if (!res.ok) throw new Error("Failed to send");
      return res.json();
    },
    onSuccess: () => {
      setMessageText("");
      queryClient.invalidateQueries({ queryKey: [api.messages.list.path, selectedContact?.id] });
    },
  });

  if (!currentUser) return null;

  const contacts = teachers?.filter(t => t.id !== currentUser.id) || [];

  return (
    <div className="flex h-screen bg-slate-50 overflow-hidden">
      <Sidebar />
      <main className="flex-1 lg:ml-72 flex flex-col h-full pt-16 lg:pt-0">
        <div className="flex flex-1 overflow-hidden">
          {/* Contacts Sidebar */}
          <div className="w-full md:w-80 border-r border-slate-200 bg-white flex flex-col shrink-0">
            <div className="p-4 border-b border-slate-100">
              <h2 className="text-xl font-bold font-display text-slate-900 mb-4">Messages</h2>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <Input placeholder="Search teachers..." className="pl-9 h-10 rounded-xl bg-slate-50 border-none" />
              </div>
            </div>
            <ScrollArea className="flex-1">
              <div className="p-2 space-y-1">
                {contacts.map((contact) => (
                  <div
                    key={contact.id}
                    onClick={() => setSelectedContact(contact)}
                    className={cn(
                      "flex items-center gap-3 p-3 rounded-xl cursor-pointer transition-all",
                      selectedContact?.id === contact.id 
                        ? "bg-blue-50 text-blue-700 shadow-sm" 
                        : "hover:bg-slate-50 text-slate-600"
                    )}
                  >
                    <div className="w-10 h-10 rounded-full bg-slate-200 flex items-center justify-center font-bold shrink-0">
                      {contact.fullName.charAt(0)}
                    </div>
                    <div className="overflow-hidden">
                      <p className="font-semibold truncate">{contact.fullName}</p>
                      <p className="text-xs text-slate-400 truncate capitalize">{contact.role}</p>
                    </div>
                  </div>
                ))}
              </div>
            </ScrollArea>
          </div>

          {/* Chat Window */}
          <div className="flex-1 flex flex-col bg-slate-50/50">
            {selectedContact ? (
              <>
                <div className="p-4 border-b border-slate-200 bg-white flex items-center gap-4">
                  <div className="w-10 h-10 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
                    {selectedContact.fullName.charAt(0)}
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-900">{selectedContact.fullName}</h3>
                    <p className="text-xs text-green-500 font-medium">Online</p>
                  </div>
                </div>

                <ScrollArea className="flex-1 p-4">
                  <div className="space-y-4">
                    {messageHistory?.map((msg) => (
                      <div
                        key={msg.id}
                        className={cn(
                          "max-w-[80%] p-3 rounded-2xl shadow-sm",
                          msg.senderId === currentUser.id 
                            ? "ml-auto bg-blue-600 text-white rounded-br-none" 
                            : "mr-auto bg-white text-slate-800 border border-slate-100 rounded-bl-none"
                        )}
                      >
                        <p className="text-sm leading-relaxed">{msg.content}</p>
                        <p className={cn(
                          "text-[10px] mt-1 opacity-70",
                          msg.senderId === currentUser.id ? "text-right" : "text-left"
                        )}>
                          {format(new Date(msg.createdAt), 'h:mm a')}
                        </p>
                      </div>
                    ))}
                    {loadingMessages && <div className="text-center text-slate-400 text-sm">Loading history...</div>}
                    {!loadingMessages && messageHistory?.length === 0 && (
                      <div className="text-center text-slate-400 text-sm mt-8 italic">
                        No messages yet. Start the conversation!
                      </div>
                    )}
                  </div>
                </ScrollArea>

                <div className="p-4 bg-white border-t border-slate-200">
                  <form 
                    onSubmit={(e) => {
                      e.preventDefault();
                      if (messageText.trim()) sendMutation.mutate(messageText);
                    }}
                    className="flex gap-2"
                  >
                    <Input 
                      placeholder="Type a message..." 
                      className="rounded-xl h-12 bg-slate-50 border-none focus-visible:ring-blue-500"
                      value={messageText}
                      onChange={(e) => setMessageText(e.target.value)}
                    />
                    <Button 
                      type="submit" 
                      size="icon" 
                      className="h-12 w-12 rounded-xl bg-blue-600 hover:bg-blue-700 shadow-lg shadow-blue-200"
                      disabled={sendMutation.isPending || !messageText.trim()}
                    >
                      <Send className="w-5 h-5" />
                    </Button>
                  </form>
                </div>
              </>
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center p-8 text-center text-slate-400">
                <div className="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mb-4">
                  <MessageSquare className="w-10 h-10 text-slate-300" />
                </div>
                <h3 className="text-xl font-bold text-slate-900 mb-2">Your Inbox</h3>
                <p className="max-w-xs">Select a teacher from the sidebar to start a secure conversation.</p>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
