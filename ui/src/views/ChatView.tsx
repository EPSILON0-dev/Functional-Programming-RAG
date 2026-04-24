import { useQuery } from "@tanstack/react-query";
import { useParams } from "react-router-dom";
import {
    AssistantMessage,
    UserMessage,
} from "../components/Messages"
import { ChatInput } from "../components/ChatInput"
import type { Conversation } from '@/types';
import { queryClient } from "@/AppContext";

export function ChatView(): React.JSX.Element {
    const { chatId } = useParams<{ chatId: string }>();

    const { data: conversation, isLoading, isError } = useQuery<Conversation>({
        queryKey: ["conversation", chatId],
        queryFn: async () => {
            const response = await fetch(`/api/chats/${chatId}`);
            if (!response.ok) {
                throw new Error("Network response was not ok");
            }
            return response.json();
        },
    });

    const mockResponseArival = async (message: string) => {
        for (let i = 0; i < message.length; i++) {
            queryClient.setQueryData(["conversation", chatId], (old: Conversation) => {
                const messages = [...old.messages];
                messages[messages.length - 1] = {
                    ...messages[messages.length - 1],
                    content: message.slice(0, i + 1) + "▌",
                };
                return { ...old, messages };
            });
            await new Promise(resolve => setTimeout(resolve, 30));
        }

        queryClient.setQueryData(["conversation", chatId], (old: Conversation) => {
            const messages = [...old.messages];
            messages[messages.length - 1] = {
                ...messages[messages.length - 1],
                content: message,
            };
            return { ...old, messages };
        });
    }

    const onMessageSent = async (message: string) => {
        console.log("Message sent:", message);
        queryClient.setQueryData(["conversation", chatId], (old: Conversation) => {
            return {
                ...old,
                messages: [...old.messages, {
                    id: "id-pending",
                    role: "user",
                    content: message,
                    timestamp: new Date().toISOString(),
                }, {
                    id: "resp-id-pending",
                    role: "assistant",
                    content: "",
                    timestamp: new Date().toISOString(),
                }]
            };
        });

        mockResponseArival("This is a mock response to your message: " + message);
    }

    return (
        <div className="flex flex-col h-screen min-w-0 flex-1">
            <header className="shrink-0 px-4 py-2 border-b">
                <div className="flex-row flex items-center gap-2">
                    <h1 className="mx-auto">{conversation?.label}</h1>
                </div>
            </header>

            <main className="flex-1 min-w-0 overflow-y-auto">
                <div className="max-w-4xl min-w-0 mx-auto h-full px-4">
                    <div className="h-8" />
                    {conversation?.messages?.map((item, index) => (
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
                    <ChatInput onMessageSent={onMessageSent} />
                </div>
            </footer>
        </div>
    );
}
