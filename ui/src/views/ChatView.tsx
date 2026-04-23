import { useQuery } from "@tanstack/react-query";
import { useParams } from "react-router-dom";
import {
    AssistantMessage,
    UserMessage,
} from "../components/Messages"
import { ChatInput } from "../components/ChatInput"
import type { Conversation } from '@/types';

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
                    <ChatInput />
                </div>
            </footer>
        </div>
    );
}
