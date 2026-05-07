import { useQuery } from "@tanstack/react-query";
import { useParams } from "react-router-dom";
import {
    AssistantMessage,
    UserMessage,
} from "../components/Messages"
import { ChatInput } from "../components/ChatInput"
import type { Chat, Message } from '@/types';
// import { queryClient } from "@/AppContext";

export function ChatView(): React.JSX.Element {
    const { chatId } = useParams<{ chatId: string }>();

    const { data: messages, isLoading: areMessagesLoading, isError: isMessagesError } = useQuery<Message[]>({
        queryKey: ["conversation", chatId],
        queryFn: async () => {
            const response = await fetch(`/api/chats/${chatId}/messages`);
            if (!response.ok) {
                throw new Error("Network response was not ok");
            }
            return response.json();
        },
    });

    const { data: chat, isLoading: isChatLoading, isError: isChatError } = useQuery<Chat>({
        queryKey: ["chat", chatId],
        queryFn: async () => {
            const response = await fetch(`/api/chats/${chatId}`);
            if (!response.ok) {
                throw new Error("Network response was not ok");
            }
            return response.json();
        },
    });


    return (
        <div className="flex flex-col h-screen min-w-0 flex-1">
            <header className="shrink-0 px-4 py-2 border-b">
                <div className="flex-row flex items-center gap-2">
                    <h1 className="mx-auto">{chat?.name || "Loading..."}</h1>
                </div>
            </header>

            <main className="flex-1 min-w-0 overflow-y-auto">
                <div className="max-w-4xl min-w-0 mx-auto h-full px-4">
                    <div className="h-8" />
                    {messages?.map((item, index) => (
                        <div key={index}>
                            {item.role === "user" ? (
                                <UserMessage message={item.content} />
                            ) : (
                                <AssistantMessage message={item.content} />
                            )}
                        </div>
                    ))}
                </div>
            </main>

            <footer className="shrink-0 px-4 py-2 border-t">
                <div className="max-w-4xl min-w-0 mx-auto h-full px-4">
                    <ChatInput onMessageSent={null} />
                </div>
            </footer>
        </div>
    );
}
